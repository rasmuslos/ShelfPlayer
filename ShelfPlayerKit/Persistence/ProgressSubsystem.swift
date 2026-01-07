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
        public let modelExecutor: any SwiftData.ModelExecutor
        public let modelContainer: SwiftData.ModelContainer
        
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
        entity(primaryID: itemID.primaryID, groupingID: itemID.groupingID, connectionID: itemID.connectionID)
    }
    func entity(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> PersistedProgress? {
        let fetchDescriptor = FetchDescriptor<PersistedProgress>(predicate: #Predicate {
            $0.connectionID == connectionID
            && $0.primaryID == primaryID
            && $0.groupingID == groupingID
        })
        
        do {
            let entities = try modelContext.fetch(fetchDescriptor).filter { $0.status != .tombstone }
            
            if !entities.isEmpty {
                if entities.count != 1 {
                    logger.error("Found \(entities.count) douplicate entities for")
                    
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
            logger.error("Error fetching progress: \(error)")
        }
        
        return nil
    }
    func createEntity(id: String, connectionID: ItemIdentifier.ConnectionID, primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, progress: Double, duration: Double?, currentTime: Double, startedAt: Date?, lastUpdate: Date, finishedAt: Date?, status: PersistedProgress.SyncStatus) -> PersistedProgress {
        let entity = PersistedProgress(id: id, connectionID: connectionID, primaryID: primaryID, groupingID: groupingID, progress: progress, duration: duration, currentTime: currentTime, startedAt: startedAt, lastUpdate: lastUpdate, finishedAt: finishedAt, status: status)
        
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
    var recentlyFinishedEntities: [ProgressEntity] {
        get throws {
            let cutoff = Date.now.advanced(by: -60 * 60 * 24 * 7)
            
            return try modelContext.fetch(FetchDescriptor<PersistedProgress>(predicate: #Predicate {
                if let finishedAt = $0.finishedAt {
                    return finishedAt > cutoff
                } else {
                    return false
                }
            })).map(ProgressEntity.init)
        }
    }
    
    func compareDatabase(against payload: [ProgressPayload], connectionID: ItemIdentifier.ConnectionID) async throws {
        var remoteDuplicates = [String]()
        
        let keyedPayload = payload.map {
            if let episodeID = $0.episodeId {
                (key(primaryID: episodeID, groupingID: $0.libraryItemId, connectionID: connectionID), $0)
            } else {
                (key(primaryID: $0.libraryItemId, groupingID: nil, connectionID: connectionID), $0)
            }
        }
        let remote = Dictionary(keyedPayload) {
            logger.warning("Found duplicate progress payload with same primary and grouping ID")
            
            guard let lhs = $0.lastUpdate else {
                return $1
            }
            
            guard let rhs = $1.lastUpdate else {
                return $0
            }
            
            remoteDuplicates.append(lhs > rhs ? $1.id : $0.id)
            return lhs > rhs ? $0 : $1
        }
        let remoteSet = Set(remote.keys)
        
        try Task.checkCancellation()
        
        let entities = try modelContext
            .fetch(FetchDescriptor<PersistedProgress>(predicate: #Predicate { $0.connectionID == connectionID }))
            .map { (key(primaryID: $0.primaryID, groupingID: $0.groupingID, connectionID: $0.connectionID), $0) }
        let local = Dictionary(uniqueKeysWithValues: entities)
        let localSet = Set(local.keys)
        
        try Task.checkCancellation()
        
        let localOnly = localSet.subtracting(remoteSet)
        let remoteOnly = remoteSet.subtracting(localSet)
        let common = localSet.intersection(remoteSet)
        
        logger.info("Comparing \(local.count) local progress entities against \(remote.count) remote progress payloads. Found \(localOnly.count) local-only, \(remoteOnly.count) remote-only, and \(common.count) common keys.")
        
        try Task.checkCancellation()
        
        var pendingServerUpdate = [String: PersistedProgress]()
        var pendingServerDeletion = [String]()
        
        var pendingLocalUpdate = [ProgressPayload]()
        var pendingLocalDeletion = [PersistedProgress.ID]()
        
        for key in localOnly {
            let entity = local[key]!
            
            if entity.status == .desynchronized {
                pendingServerUpdate[key] = entity
            } else {
                pendingLocalDeletion.append(entity.id)
            }
        }
        
        for key in remoteOnly {
            let payload = remote[key]!
            pendingLocalUpdate.append(payload)
        }
        
        for key in common {
            let localEntity = local[key]!
            let remotePayload = remote[key]!
            
            if localEntity.duration == nil, let duration = remotePayload.duration {
                localEntity.duration = duration
            }
            
            guard localEntity.status != .tombstone else {
                pendingServerDeletion.append(remotePayload.id)
                continue
            }
            
            guard let lastUpdate = remotePayload.lastUpdate else {
                pendingServerUpdate[key] = localEntity
                continue
            }
            
            let remoteUpdated = Date(timeIntervalSince1970: Double(lastUpdate) / 1000)
            
            let currentTime = remotePayload.currentTime
            
            if let currentTime, isEqual(localEntity.currentTime, rhs: currentTime) {
                continue
            } else if remoteUpdated < localEntity.lastUpdate {
                logger.info("Local entity \(localEntity.id) is newer then remote.")
                pendingServerUpdate[key] = localEntity
            } else {
                logger.info("Remote entity is newer then \(localEntity.id)")
                pendingLocalUpdate.append(remotePayload)
            }
        }
        
        try Task.checkCancellation()
        
        // We should no longer cancel the task from the point onwards. The network requests are performed first.
        
        logger.info("Computed changes: \(pendingServerUpdate.count) remote updates, \(pendingServerDeletion.count) remote deletions, \(pendingLocalUpdate.count) local updates, \(pendingLocalDeletion.count) local deletions (\(remoteDuplicates.count) duplicates)")
        
        // Run server updates
        
        if !pendingServerUpdate.isEmpty {
            try await ABSClient[connectionID].batchUpdate(progress: pendingServerUpdate.values.map { .init(persistedEntity: $0) })
        }
        
        for id in pendingServerDeletion {
            try await ABSClient[connectionID].delete(progressID: id)
        }
        for id in remoteDuplicates {
            do {
                try await ABSClient[connectionID].delete(progressID: id)
            } catch {
                logger.warning("Failed to delete remote duplicate \(id): \(error)")
            }
        }
        
        // Apply database changes
        
        pendingServerUpdate.forEach {
            $1.status = .synchronized
        }
        
        let pendingDeletionIDs = local.values.filter { $0.status == .tombstone }.map(\.id)
        try modelContext.delete(model: PersistedProgress.self, where: #Predicate {
            pendingDeletionIDs.contains($0.id)
        })
        
        try modelContext.delete(model: PersistedProgress.self, where: #Predicate {
            pendingLocalDeletion.contains($0.id)
        })
        
        for payload in pendingLocalUpdate {
            let entity = integrate(connectionID: connectionID,
                                   primaryID: payload.episodeId ?? payload.libraryItemId,
                                   groupingID: payload.episodeId == nil ? nil : payload.libraryItemId,
                                   progress: payload.progress ?? 0,
                                   duration: payload.duration,
                                   currentTime: payload.currentTime ?? 0,
                                   startedAt: payload.startedAt != nil ? Date(timeIntervalSince1970: Double(payload.startedAt!) / 1000) : nil,
                                   lastUpdate: payload.lastUpdate != nil ? Date(timeIntervalSince1970: Double(payload.lastUpdate!) / 1000) : .now,
                                   finishedAt: payload.finishedAt != nil ? Date(timeIntervalSince1970: Double(payload.finishedAt!) / 1000) : nil)
            
            entity.status = .synchronized
        }
        
        try modelContext.save()
    }
    
    func markAsCompleted(_ itemIDs: [ItemIdentifier]) async throws {
        logger.info("Marking progress as completed for items \(itemIDs).")
        
        var persisted = [PersistedProgress]()
        
        for itemID in itemIDs {
            let entity = integrate(connectionID: itemID.connectionID,
                                   primaryID: itemID.primaryID,
                                   groupingID: itemID.groupingID,
                                   progress: 1,
                                   duration: nil,
                                   currentTime: 0,
                                   startedAt: .now,
                                   lastUpdate: .now,
                                   finishedAt: .now)
            
            entity.status = .desynchronized
            persisted.append(entity)
        }
        
        try modelContext.save()
        
        for entity in persisted {
            progressEntityDidUpdate(.init(persistedEntity: entity))
        }
        
        guard await !OfflineMode.shared.isEnabled else {
            return
        }
        
        do {
            let grouped = Dictionary(grouping: persisted) { $0.connectionID }
            
            for connectionID in grouped.keys {
                try await ABSClient[connectionID].batchUpdate(progress: grouped[connectionID]!.map { .init(persistedEntity: $0) })
            }
            
            for entity in persisted {
                entity.status = .synchronized
            }
        } catch {
            logger.info("Caching progress failed update because of: \(error.localizedDescription).")
        }
        
        try modelContext.save()
    }
    func markAsListening(_ itemIDs: [ItemIdentifier]) async throws {
        logger.info("Marking progress as listening for items \(itemIDs).")
        
        var persisted = [PersistedProgress]()
        
        for itemID in itemIDs {
            let entity = integrate(connectionID: itemID.connectionID,
                                   primaryID: itemID.primaryID,
                                   groupingID: itemID.groupingID,
                                   progress: 0,
                                   duration: nil,
                                   currentTime: 0,
                                   startedAt: nil,
                                   lastUpdate: .now,
                                   finishedAt: nil)
            
            entity.status = .desynchronized
            persisted.append(entity)
        }
        
        try modelContext.save()
        
        for entity in persisted {
            progressEntityDidUpdate(.init(persistedEntity: entity))
        }
        
        guard await !OfflineMode.shared.isEnabled else {
            return
        }
        
        do {
            let grouped = Dictionary(grouping: persisted) { $0.connectionID }
            
            for connectionID in grouped.keys {
                try await ABSClient[connectionID].batchUpdate(progress: grouped[connectionID]!.map { .init(persistedEntity: $0) })
            }
            
            for entity in persisted {
                entity.status = .synchronized
            }
        } catch {
            logger.info("Caching progress failed update because of: \(error.localizedDescription).")
        }
        
        try modelContext.save()
    }
    
    func update(_ itemID: ItemIdentifier, currentTime: Double, duration: Double) async throws {
        let targetEntity: PersistedProgress
        
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
        } else {
            targetEntity = createEntity(id: UUID().uuidString, connectionID: itemID.connectionID, primaryID: itemID.primaryID, groupingID: itemID.groupingID, progress: progress, duration: duration, currentTime: currentTime, startedAt: .now, lastUpdate: .now, finishedAt: progress >= 1 ? .now : nil, status: .desynchronized)
        }
        
        try modelContext.save()
        
        let entity = ProgressEntity(persistedEntity: targetEntity)
        await RFNotification[.progressEntityUpdated].send(payload: (entity.connectionID, entity.primaryID, entity.groupingID, entity))
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
    
    func flush() throws {
        try modelContext.delete(model: PersistedProgress.self)
        try modelContext.save()
    }
}

private extension PersistenceManager.ProgressSubsystem {
    private func key(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?, connectionID: ItemIdentifier.ConnectionID) -> String {
        "\(connectionID)-\(primaryID)-\(groupingID ?? "_")"
    }
    
    func integrate(connectionID: ItemIdentifier.ConnectionID,
                   primaryID: ItemIdentifier.PrimaryID,
                   groupingID: ItemIdentifier.GroupingID?,
                   progress: Double,
                   duration: Double?,
                   currentTime: Double,
                   startedAt: Date?,
                   lastUpdate: Date,
                   finishedAt: Date?) -> PersistedProgress {
        let updated: PersistedProgress

        if let existing = self.entity(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
            existing.progress = progress
            existing.currentTime = currentTime
            
            if let duration, duration > 0 {
                existing.duration = duration
            }
            if progress >= 1, let duration = existing.duration {
                existing.currentTime = duration
            }
            
            existing.startedAt = startedAt
            existing.lastUpdate = lastUpdate
            existing.finishedAt = finishedAt
            updated = existing
        } else {
            updated = createEntity(id: UUID().uuidString,
                                   connectionID: connectionID,
                                   primaryID: primaryID,
                                   groupingID: groupingID,
                                   progress: progress,
                                   duration: duration,
                                   currentTime: currentTime,
                                   startedAt: startedAt,
                                   lastUpdate: lastUpdate,
                                   finishedAt: finishedAt,
                                   status: .synchronized)
            
            modelContext.insert(updated)
        }

        return updated
    }
    func isEqual(_ lhs: TimeInterval, rhs: TimeInterval) -> Bool {
        lhs.distance(to: rhs) < .ulpOfOne
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func hideFromContinueListening(connectionID: ItemIdentifier.ConnectionID) -> Key<Set<String>> {
        Key(identifier: "hideFromContinueListening_\(connectionID)", cluster: "hideFromContinueListening", isCachePurgeable: true)
    }
}
