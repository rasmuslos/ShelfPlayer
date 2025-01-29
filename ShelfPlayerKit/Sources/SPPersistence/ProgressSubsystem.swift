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
import SPFoundation
import SPNetwork

typealias PersistedProgress = SchemaV2.PersistedProgress

extension PersistenceManager {
    public final actor ProgressSubsystem: ModelActor {
        public nonisolated let modelExecutor: any SwiftData.ModelExecutor
        public nonisolated let modelContainer: SwiftData.ModelContainer
        
        let logger: Logger
        let signposter: OSSignposter
        
        public init(modelContainer: SwiftData.ModelContainer) {
            let modelContext = ModelContext(modelContainer)
            
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Progress")
            signposter = .init(logger: logger)
        }
    }
}

extension PersistenceManager.ProgressSubsystem {
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
        
        logger.warning("Missing progress for \(itemID)")
        
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
        
        RFNotification[.progressEntityUpdated].send((entity.connectionID, entity.primaryID, entity.groupingID, nil))
    }
    
    nonisolated func progressEntityDidUpdate(_ entity: ProgressEntity) {
        RFNotification[.progressEntityUpdated].send((entity.connectionID, entity.primaryID, entity.groupingID, entity))
    }
}

public extension PersistenceManager.ProgressSubsystem {
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
        RFNotification[.progressEntityUpdated].send((entity.connectionID, entity.primaryID, entity.groupingID, entity))
        
        do {
            try await ABSClient[itemID.connectionID].batchUpdate(progress: [entity])
            
            persistedEntity.status = .synchronized
            try modelContext.save()
        } catch {
            logger.info("Caching progress update because of: \(error.localizedDescription).")
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
            
            var pendingDeletion = [(id: String, connectionID: String)]()
            var pendingCreation = [ProgressEntity]()
            var pendingUpdate = [ProgressEntity]()
            
            try modelContext.transaction {
                try modelContext.enumerate(FetchDescriptor<PersistedProgress>()) { entity in
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
                        
                        if delta < 0 {
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
                        modelContext.delete(entity)
                    }
                }
            }
            
            signposter.emitEvent("transaction", id: signpostID)
            try Task.checkCancellation()
            
            logger.info("Deleting \(pendingDeletion.count) progress entities")
            
            for (id, connectionID) in pendingDeletion {
                try? await ABSClient[connectionID].delete(progressID: id)
            }
            
            signposter.emitEvent("delete", id: signpostID)
            try Task.checkCancellation()
            
            let batch = pendingCreation + pendingUpdate
            let grouped = Dictionary(batch.map { ($0.connectionID, [$0]) }, uniquingKeysWith: +)
            
            logger.info("Batch updating \(batch.count) progress entities from \(grouped.count) servers")
            
            for (connectionID, entities) in grouped {
                try await ABSClient[connectionID].batchUpdate(progress: entities)
            }
            
            signposter.emitEvent("batch", id: signpostID)
            try Task.checkCancellation()
            
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
            
            signposter.emitEvent("cleanup", id: signpostID)
            try Task.checkCancellation()
            
            try modelContext.save()
            
            signposter.endInterval("sync", signpostState)
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
        guard let entity = entity(itemID) else {
            logger.warning("Creating new progress stub for \(itemID)")
            return .init(id: UUID().uuidString, connectionID: itemID.connectionID, primaryID: itemID.primaryID, groupingID: itemID.groupingID, progress: 0, duration: nil, currentTime: 0, startedAt: nil, lastUpdate: .now, finishedAt: nil)
        }
        
        return .init(persistedEntity: entity)
    }
}
