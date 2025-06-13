//
//  Progress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import OSLog
import SwiftData
import RFNotifications

typealias PersistedProgress = SchemaV2.PersistedProgress

extension PersistenceManager {
    public final actor ProgressSubsystem: ModelActor {
        public nonisolated let modelExecutor: any SwiftData.ModelExecutor
        public nonisolated let modelContainer: SwiftData.ModelContainer
        
        let logger: Logger
        let signposter: OSSignposter
        
        init(modelContainer: SwiftData.ModelContainer) {
            let modelContext = ModelContext(modelContainer)
            
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Progress")
            signposter = .init(logger: logger)
        }
    }
}

extension PersistenceManager.ProgressSubsystem {
    func entity(_ id: String) -> PersistedProgress? {
        try? modelContext.fetch(FetchDescriptor<PersistedProgress>(predicate: #Predicate {
            $0.id == id
        })).first
    }
    func entity(_ itemID: ItemIdentifier) -> PersistedProgress? {
        let connectionID = itemID.connectionID
        let primaryID = itemID.primaryID
        let groupingID = itemID.groupingID
        
        let fetchDescriptor = FetchDescriptor<PersistedProgress>(predicate: #Predicate {
            $0.connectionID == connectionID
            && $0.primaryID == primaryID
            && $0.groupingID == groupingID
            // libraryID does not exist
            // type can be ignored
        })
        
        // Return existing
        
        do {
            let entities = try modelContext.fetch(fetchDescriptor).filter { $0.status != .tombstone }
            
            if !entities.isEmpty {
                if entities.count != 1 {
                    logger.error("Found \(entities.count) progress entities for \(itemID)")
                    
                    var sorted = entities.sorted { $0.lastUpdate > $1.lastUpdate }
                    sorted.removeFirst()
                    
                    for entity in sorted {
                        Task {
                            try await delete(entity)
                        }
                    }
                }
                
                return entities.first
            }
        } catch {
            logger.error("Error fetching progress for \(itemID): \(error)")
        }
        
        return nil
    }
    func createEntity(id: String, itemID: ItemIdentifier, progress: Double, duration: Double?, currentTime: Double, startedAt: Date?, lastUpdate: Date, finishedAt: Date?, status: PersistedProgress.SyncStatus) -> PersistedProgress {
        let entity = PersistedProgress(id: id, connectionID: itemID.connectionID, primaryID: itemID.primaryID, groupingID: itemID.groupingID, progress: progress, duration: duration, currentTime: currentTime, startedAt: startedAt, lastUpdate: lastUpdate, finishedAt: finishedAt, status: status)
        modelContext.insert(entity)
        
        return entity
    }
    func delete(_ entity: PersistedProgress) async throws {
        logger.info("Deleting progress entity \(entity.id).")
        
        do {
            try await ABSClient[entity.connectionID].delete(progressID: entity.id)
        } catch {
            entity.status = .tombstone
        }
        
        modelContext.delete(entity)
        try modelContext.save()
        
        await RFNotification[.progressEntityUpdated].send(payload: (entity.connectionID, entity.primaryID, entity.groupingID, nil))
    }
    
    func remove(itemID: ItemIdentifier) {
        let primaryID = itemID.primaryID
        let groupingID = itemID.groupingID
        let connectionID = itemID.connectionID
        
        do {
            try modelContext.delete(model: PersistedProgress.self, where: #Predicate {
                $0.primaryID == primaryID
                && $0.groupingID == groupingID
                && $0.connectionID == connectionID
            })
            try modelContext.save()
        } catch {
            logger.error("Failed to remove progress entities related to itemID \(itemID): \(error)")
        }
    }
    func remove(connectionID: ItemIdentifier.ConnectionID) {
        do {
            try modelContext.delete(model: PersistedProgress.self, where: #Predicate {
                $0.connectionID == connectionID
            })
            try modelContext.save()
        } catch {
            logger.error("Failed to remove progress entities related to connection \(connectionID): \(error)")
        }
    }
    
    nonisolated func progressEntityDidUpdate(_ entity: ProgressEntity) {
        Task {
            await RFNotification[.progressEntityUpdated].send(payload: (entity.connectionID, entity.primaryID, entity.groupingID, entity))
        }
    }
    
    func merge(duplicates entities: [ProgressPayload], connectionID: ItemIdentifier.ConnectionID) async throws -> ProgressPayload? {
        guard entities.count > 1 else {
            logger.error("Invalid sequence passed to merge duplicates: \(entities)")
            return nil
        }
        
        logger.warning("Found \(entities.count) progress entities for the same item: \(entities).")
        
        let mostRecent = entities.max {
            guard let lhs = $0.lastUpdate else {
                return false
            }
            guard let rhs = $1.lastUpdate else {
                return true
            }
            
            guard lhs != rhs else {
                guard let lhsCurrentTime = $0.currentTime else {
                    return false
                }
                guard let rhsCurrentTime = $1.currentTime else {
                    return true
                }
                
                return lhsCurrentTime > rhsCurrentTime
            }
            
            return lhs > rhs
        }!
        let remaining = entities.compactMap { $0.id == mostRecent.id ? nil : $0.id }
        
        for entityID in remaining {
            try await ABSClient[connectionID].delete(progressID: entityID)
        }
        
        logger.info("Merged progress entities. Now at \(mostRecent.currentTime?.formatted() ?? "?")")
        
        return mostRecent
    }
}

public extension PersistenceManager.ProgressSubsystem {
    nonisolated func hiddenFromContinueListening(connectionID: ItemIdentifier.ConnectionID) async -> Set<String> {
        await PersistenceManager.shared.keyValue[.hideFromContinueListening(connectionID: connectionID)] ?? []
    }
    
    var activeProgressEntities: [ProgressEntity] {
        get throws {
            try modelContext.fetch(FetchDescriptor<PersistedProgress>(predicate: #Predicate {
                $0.progress > 0 && $0.progress < 1
            })).map(ProgressEntity.init)
        }
    }
    
    func markAsCompleted(_ itemID: ItemIdentifier) async throws {
        logger.info("Marking progress as completed for item \(itemID).")
        
        let pendingUpdate: PersistedProgress
        
        if let entity = entity(itemID) {
            entity.progress = 1
            
            if let duration = entity.duration {
                entity.currentTime = duration
            }
            
            if entity.startedAt == nil {
                entity.startedAt = .now
            }
            
            entity.finishedAt = .now
            entity.lastUpdate = .now
            
            entity.status = .desynchronized
            
            try modelContext.save()
            
            pendingUpdate = entity
        } else {
            pendingUpdate = createEntity(id: UUID().uuidString, itemID: itemID, progress: 1, duration: nil, currentTime: 0, startedAt: .now, lastUpdate: .now, finishedAt: .now, status: .desynchronized)
        }
        
        let entity = ProgressEntity(persistedEntity: pendingUpdate)
        
        progressEntityDidUpdate(entity)
        
        do {
            try await ABSClient[itemID.connectionID].batchUpdate(progress: [entity])
            
            pendingUpdate.status = .synchronized
            try modelContext.save()
        } catch {
            logger.info("Caching progress update because of: \(error.localizedDescription).")
        }
    }
    func markAsListening(_ itemID: ItemIdentifier) async throws {
        logger.info("Marking progress as listening for item \(itemID).")
        
        guard let persistedEntity = entity(itemID) else {
            logger.warning("Could not mark progress as listening for item \(itemID) because it does not exist.")
            return
        }
        
        persistedEntity.progress = 0
        persistedEntity.currentTime = 0
        
        persistedEntity.startedAt = nil
        persistedEntity.finishedAt = nil
        persistedEntity.lastUpdate = .now
        
        persistedEntity.status = .desynchronized
        
        try modelContext.save()
        
        let entity = ProgressEntity(persistedEntity: persistedEntity)
        await RFNotification[.progressEntityUpdated].send(payload: (entity.connectionID, entity.primaryID, entity.groupingID, entity))
        
        do {
            try await ABSClient[itemID.connectionID].batchUpdate(progress: [entity])
            
            persistedEntity.status = .synchronized
            try modelContext.save()
        } catch {
            logger.info("Caching progress update because of: \(error.localizedDescription).")
        }
    }
    
    func update(_ itemID: ItemIdentifier, currentTime: Double, duration: Double, notifyServer: Bool) async throws {
        let targetEntity: PersistedProgress
        
        print(currentTime)
        
        let progress = currentTime / duration
        
        if let existingEntity = entity(itemID) {
            targetEntity = existingEntity
            
            targetEntity.progress = progress
            targetEntity.duration = duration
            targetEntity.currentTime = currentTime
            
            if targetEntity.startedAt == nil {
                targetEntity.startedAt = nil
            }
            
            if progress >= 1 {
                targetEntity.finishedAt = .now
            } else {
                targetEntity.finishedAt = nil
            }
            
            targetEntity.lastUpdate = .now
            
            if notifyServer {
                targetEntity.status = .desynchronized
            }
        } else {
            targetEntity = createEntity(id: UUID().uuidString, itemID: itemID, progress: progress, duration: duration, currentTime: currentTime, startedAt: .now, lastUpdate: .now, finishedAt: progress >= 1 ? .now : nil, status: notifyServer ? .desynchronized : .tombstone)
        }
        
        try modelContext.save()
        
        let entity = ProgressEntity(persistedEntity: targetEntity)
        
        await RFNotification[.progressEntityUpdated].send(payload: (entity.connectionID, entity.primaryID, entity.groupingID, entity))
        
        if notifyServer {
            do {
                try await ABSClient[itemID.connectionID].batchUpdate(progress: [entity])
                
                targetEntity.status = .synchronized
                try modelContext.save()
            } catch {
                logger.info("Caching progress update because of: \(error.localizedDescription).")
            }
        }
    }
    
    /// Insert changes into the database and notify the connection of pending updates
    ///
    /// This function will:
    /// 1. update or delete existing progress entities
    /// 2. send detected differences to server
    /// 3. create missing local entities
    func sync(sessions payload: [ProgressPayload], connectionID: ItemIdentifier.ConnectionID) async throws {
        var payload = payload
        
        do {
            let signpostID = signposter.makeSignpostID()
            let signpostState = signposter.beginInterval("sync", id: signpostID)
            
            logger.info("Initiating sync with \(payload.count) entities")
            
            try modelContext.save()
            
            signposter.emitEvent("mapIDs", id: signpostID)
            
            // Should be updated on the server:
            
            var pendingDeletion = [(id: String, connectionID: String)]()
            var pendingCreation = [ProgressEntity]()
            var pendingUpdate = [ProgressEntity]()
            
            var hiddenIDs = [(ItemIdentifier.ConnectionID, String)]()
            
            // MARK: Remove duplicates
            
            let duplicateIDs = Dictionary(grouping: payload, by: \.libraryItemId).filter { $0.value.count > 1 }
            var mergedEntities = [ProgressPayload]()
            
            for (_, entities) in duplicateIDs {
                // Always proceed with audiobooks and only continue with duplicate episodes
                
                let isAudiobook = entities.allSatisfy { $0.episodeId == nil }
                
                if isAudiobook, let merged = try? await merge(duplicates: entities, connectionID: connectionID) {
                    mergedEntities.append(merged)
                } else if !isAudiobook {
                    let episodeIDs = Dictionary(grouping: entities, by: \.episodeId).filter { $0.value.count > 1 }
                    
                    guard !episodeIDs.isEmpty else {
                        continue
                    }
                    
                    for (_, entities) in episodeIDs {
                        guard let entity = try? await merge(duplicates: entities, connectionID: connectionID) else {
                            logger.info("Failed to merge duplicate episode progress: \(entities)")
                            continue
                        }
                        
                        mergedEntities.append(entity)
                    }
                } else {
                    logger.info("Failed to merge duplicate audiobook progress: \(entities)")
                }
            }
            
            for merged in mergedEntities {
                payload.removeAll {
                    $0.libraryItemId == merged.libraryItemId
                    && $0.episodeId == merged.episodeId
                }
                
                payload.append(merged)
            }
            
            // MARK: Enumerate database and update existing
            
            try modelContext.transaction {
                try modelContext.enumerate(FetchDescriptor<PersistedProgress>(predicate: #Predicate {
                    $0.connectionID == connectionID
                })) { entity in
                    try Task.checkCancellation()
                    
                    let id = entity.id
                    
                    guard let index = payload.firstIndex(where: { $0.id == id }) else {
                        if entity.status == .desynchronized {
                            pendingCreation.append(.init(persistedEntity: entity))
                        } else {
                            modelContext.delete(entity)
                        }
                        
                        return
                    }
                    
                    let payload = payload.remove(at: index)
                    
                    if payload.hideFromContinueListening == true {
                        hiddenIDs.insert((connectionID, payload.episodeId ?? payload.libraryItemId), at: 0)
                    }
                    
                    switch entity.status {
                    case .synchronized, .desynchronized:
                        guard let lastUpdate = payload.lastUpdate else {
                            pendingUpdate.append(.init(persistedEntity: entity))
                            return
                        }
                        
                        let delta = Int(lastUpdate / 1000).distance(to: Int(entity.lastUpdate.timeIntervalSince1970))
                        
                        if delta == 0 && entity.status == .synchronized {
                            return
                        }
                        
                        guard delta > 0 else {
                            pendingUpdate.append(.init(persistedEntity: entity))
                            return
                        }
                        
                        if let duration = payload.duration, duration > 0 {
                            entity.duration = duration
                        } else {
                            entity.duration = nil
                        }
                        
                        entity.currentTime = payload.currentTime ?? 0
                        
                        entity.progress = payload.progress ?? 0
                        
                        if let startedAt = payload.startedAt {
                            entity.startedAt = Date(timeIntervalSince1970: Double(startedAt) / 1000)
                        } else {
                            entity.startedAt = nil
                        }
                        
                        if let lastUpdate = payload.lastUpdate {
                            entity.lastUpdate = Date(timeIntervalSince1970: Double(lastUpdate) / 1000)
                        } else {
                            entity.lastUpdate = .now
                        }
                        
                        if let finishedAt = payload.finishedAt {
                            entity.finishedAt = Date(timeIntervalSince1970: Double(finishedAt) / 1000)
                        } else {
                            entity.finishedAt = nil
                        }
                        
                        entity.status = .synchronized
                    case .tombstone:
                        pendingDeletion.append((id, entity.connectionID))
                    }
                }
            }
            
            // MARK: Hidden IDs
            
            for (connectionID, ids) in Dictionary(hiddenIDs.map { ($0.0, [$0.1]) }, uniquingKeysWith: +) {
                logger.info("\(ids.count) progress entities hidden from Continue Listening for connection \(connectionID)")
                try await PersistenceManager.shared.keyValue.set(.hideFromContinueListening(connectionID: connectionID), .init(ids))
            }
            
            signposter.emitEvent("transaction", id: signpostID)
            try Task.checkCancellation()
            
            // MARK: Create missing local
            
            // try modelContext.transaction {
            for payload in payload {
                let _ = createEntity(id: payload.id,
                                     itemID: .init(primaryID: payload.episodeId ?? payload.libraryItemId,
                                                   groupingID: payload.episodeId != nil ? payload.libraryItemId : nil,
                                                   libraryID: "_",
                                                   connectionID: connectionID,
                                                   type: payload.episodeId != nil ? .episode : .audiobook),
                                     progress: payload.progress ?? 0,
                                     duration: payload.duration ?? 0,
                                     currentTime: payload.currentTime ?? 0,
                                     startedAt: payload.startedAt != nil ? Date(timeIntervalSince1970: Double(payload.startedAt!) / 1000) : nil,
                                     lastUpdate: payload.lastUpdate != nil ? Date(timeIntervalSince1970: Double(payload.lastUpdate!) / 1000) : .now,
                                     finishedAt: payload.lastUpdate != nil ? Date(timeIntervalSince1970: Double(payload.lastUpdate!) / 1000) : nil,
                                     status: .synchronized)
            }
            // }
            
            signposter.emitEvent("create", id: signpostID)
            try Task.checkCancellation()
            
            // MARK: Create & Update remote
            
            let batch = pendingCreation + pendingUpdate
            let grouped = Dictionary(batch.map { ($0.connectionID, [$0]) }, uniquingKeysWith: +)
            
            logger.info("Batch updating \(batch.count) progress entities from \(grouped.count) servers")
            
            for (connectionID, entities) in grouped {
                try await ABSClient[connectionID].batchUpdate(progress: entities)
                
                for entity in entities {
                    guard let persisted = self.entity(entity.id) else {
                        continue
                    }
                    
                    persisted.status = .synchronized
                }
            }
            
            signposter.emitEvent("batch", id: signpostID)
            try Task.checkCancellation()
            
            // MARK: Delete remote
            
            logger.info("Deleting \(pendingDeletion.count) progress entities")
            
            for (id, connectionID) in pendingDeletion {
                do {
                    try await ABSClient[connectionID].delete(progressID: id)
                } catch {
                    logger.error("Failed to delete progress entity \(id): \(error)")
                }
                
                guard let persisted = entity(id) else {
                    continue
                }
                
                try await delete(persisted)
            }
            
            signposter.emitEvent("delete", id: signpostID)
            
            // MARK: End
            
            try modelContext.save()
            
            signposter.endInterval("sync", signpostState)
            
            await RFNotification[.invalidateProgressEntities].send(payload: connectionID)
        } catch {
            logger.error("Error while syncing progress: \(error)")
            
            modelContext.rollback()
            try modelContext.save()
            
            throw error
        }
    }
    
    func delete(itemID: ItemIdentifier) async throws {
        if let entity = entity(itemID) {
            try await delete(entity)
        }
    }
    
    subscript(_ itemID: ItemIdentifier) -> ProgressEntity {
        if let entity = entity(itemID) {
            .init(persistedEntity: entity)
        } else {
            .init(id: UUID().uuidString, connectionID: itemID.connectionID, primaryID: itemID.primaryID, groupingID: itemID.groupingID, progress: 0, duration: nil, currentTime: 0, startedAt: nil, lastUpdate: .now, finishedAt: nil)
        }
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func hideFromContinueListening(connectionID: ItemIdentifier.ConnectionID) -> Key<Set<String>> {
        Key(identifier: "hideFromContinueListening_\(connectionID)", cluster: "hideFromContinueListening", isCachePurgeable: true)
    }
}
