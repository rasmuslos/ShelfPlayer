//
//  OfflineManager+Progress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import Defaults
import SPFoundation
import SPNetwork

// MARK: Internal (Higher order)

internal extension OfflineManager {
    func progressEntities() throws -> [OfflineProgress] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineProgress>(sortBy: [SortDescriptor(\.lastUpdate)])
        
        return try context.fetch(descriptor)
    }
    
    func progressEntity(itemID: ItemIdentifier) -> OfflineProgress {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let entity = progressEntity(itemID: itemID, context: context) {
            return entity
        }
        
        let progress = OfflineProgress(
            id: "tmp_\(itemID.episodeID ?? itemID.primaryID)",
            itemID: itemID.primaryID,
            episodeID: itemID.episodeID,
            progress: 0,
            duration: 0,
            currentTime: 0,
            startedAt: nil,
            lastUpdate: .now,
            finishedAt: nil,
            progressType: .localSynced)
        
        context.insert(progress)
        try? context.save()
        
        return progress
    }
    
    func deleteProgressEntity(id: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let entities = try? context.fetch(.init(predicate: #Predicate<OfflineProgress> { $0.id == id }))
        
        try context.delete(model: OfflineProgress.self, where: #Predicate { $0.id == id })
        try context.save()
        
        if let entities {
            for entity in entities {
                ProgressEntity.updatedSubject.send(.init(itemID: entity.itemID, episodeID: entity.episodeID))
            }
        }
    }
    
    func syncCachedProgressEntities() async throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let cached = try OfflineManager.shared.progressEntities(type: .localCached, context: context)
        
        for progress in cached {
            try await AudiobookshelfClient.shared.updateProgress(itemId: progress.itemID, episodeId: progress.episodeID, currentTime: progress.currentTime, duration: progress.duration)
            
            updateSyncState(.localSynced, itemID: .init(itemID: progress.itemID, episodeID: progress.episodeID))
        }
    }
    
    func updateSyncState(_ type: OfflineProgress.ProgressSyncState, itemID: ItemIdentifier) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let entity = progressEntity(itemID: itemID, context: context)
        
        entity?.progressType = type
        try? context.save()
    }
    
    func updateLocalProgressEntities(mediaProgress: [MediaProgress], context: ModelContext) throws {
        var hideFromContinueListening = [HideFromContinueListeningEntity]()
        
        try context.transaction {
            for mediaProgress in mediaProgress {
                if mediaProgress.hideFromContinueListening {
                    hideFromContinueListening.append(.init(itemId: mediaProgress.libraryItemId, episodeId: mediaProgress.episodeId))
                }
                
                let existing = progressEntity(itemID: .init(itemID: mediaProgress.libraryItemId, episodeID: mediaProgress.episodeId), context: context)
                let duration = mediaProgress.duration ?? 0
                
                if let existing = existing {
                    if Int64(existing.lastUpdate.timeIntervalSince1970 * 1000) < mediaProgress.lastUpdate {
                        logger.info("Updating progress: \(existing.id)")
                        
                        existing.id = mediaProgress.id
                        
                        existing.progress = mediaProgress.progress
                        
                        existing.duration = duration
                        existing.currentTime = mediaProgress.currentTime
                        
                        existing.startedAt = Date(timeIntervalSince1970: Double(mediaProgress.startedAt) / 1000)
                        existing.lastUpdate = Date(timeIntervalSince1970: Double(mediaProgress.lastUpdate) / 1000)
                        
                        if let finishedAt = mediaProgress.finishedAt {
                            existing.finishedAt = Date(timeIntervalSince1970: Double(finishedAt) / 1000)
                        } else {
                            existing.finishedAt = nil
                        }
                    }
                } else {
                    logger.info("Creating progress: \(mediaProgress.id)")
                    
                    let finishedAt: Date?
                    
                    if let finishedAtTime = mediaProgress.finishedAt {
                        finishedAt = Date(timeIntervalSince1970: Double(finishedAtTime) / 1000)
                    } else {
                        finishedAt = nil
                    }
                    
                    let progress = OfflineProgress(
                        id: mediaProgress.id,
                        itemID: mediaProgress.libraryItemId,
                        episodeID: mediaProgress.episodeId,
                        progress: mediaProgress.progress,
                        duration: duration,
                        currentTime: mediaProgress.currentTime,
                        startedAt: Date(timeIntervalSince1970: Double(mediaProgress.startedAt) / 1000),
                        lastUpdate: Date(timeIntervalSince1970: Double(mediaProgress.lastUpdate) / 1000),
                        finishedAt: finishedAt,
                        progressType: .receivedFromServer)
                    
                    context.insert(progress)
                }
            }
        }
        
        Defaults[.hideFromContinueListening] = hideFromContinueListening
    }
}

// MARK: Internal (Helper)

internal extension OfflineManager {
    func progressEntity(itemID: ItemIdentifier, context: ModelContext) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.itemID == itemID.primaryID && $0.episodeID == itemID.episodeID })
        descriptor.fetchLimit = 1
        
        return try? context.fetch(descriptor).first
    }
    
    func progressEntities(type: OfflineProgress.ProgressSyncState, context: ModelContext) throws -> [OfflineProgress] {
        try context.fetch(.init()).filter { $0.progressType == type }
    }
    
    func deleteProgressEntities(type: OfflineProgress.ProgressSyncState, context: ModelContext) throws {
        for entity in try progressEntities(type: type, context: context) {
            context.delete(entity)
        }
        
        try context.save()
        ProgressEntity.updatedSubject.send(nil)
    }
}

// MARK: Public (Higher order)

public extension OfflineManager {
    var hasCachedChanges: Bool {
        let entities = try? progressEntities().filter { $0.progressType == .localCached }
        
        guard let count = entities?.count else {
            return false
        }
        
        return count > 0
    }
    
    func progressEntity(id: String) -> ProgressEntity {
        let entity = progressEntity(id: id)
        
        return .init(
            id: entity.id,
            itemID: entity.itemID,
            episodeID: entity.episodeID,
            progress: entity.progress,
            duration: entity.duration,
            currentTime: entity.currentTime,
            startedAt: entity.startedAt,
            lastUpdate: entity.lastUpdate,
            finishedAt: entity.finishedAt)
    }
    
    func progressEntity(item: Item) -> ProgressEntity {
        let entity = progressEntity(itemID: item.id)
        
        return .init(
            id: entity.id,
            itemID: entity.itemID,
            episodeID: entity.episodeID,
            progress: entity.progress,
            duration: entity.duration,
            currentTime: entity.currentTime,
            startedAt: entity.startedAt,
            lastUpdate: entity.lastUpdate,
            finishedAt: entity.finishedAt)
    }
    
    func resetProgressEntity(id: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        try context.delete(model: OfflineProgress.self, where: #Predicate {
            $0.id == id
        })
        try context.save()
        
        // TODO: Broken
        // NotificationCenter.default.post(name: ProgressEntity.progressUpdatedNotification, object: convertIdentifier(itemID: itemID, episodeID: episodeID))
    }
    
    func resetProgressEntity(itemID: ItemIdentifier) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        try context.delete(model: OfflineProgress.self, where: #Predicate {
            $0.itemID == itemID.primaryID && $0.episodeID == itemID.episodeID
        })
        try context.save()
        
        ProgressEntity.updatedSubject.send(itemID)
    }
    
    func deleteProgressEntities() throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
            
        try context.delete(model: OfflineProgress.self)
        try context.save()
        
        ProgressEntity.updatedSubject.send(nil)
    }
    
    func finished(_ finished: Bool, item: Item, synced: Bool) {
        let entity = progressEntity(itemID: item.id)
        
        if finished {
            entity.progress = 1
            entity.currentTime = entity.duration
            
            entity.finishedAt = .now
        } else {
            entity.progress = 0
            entity.currentTime = 0
            
            entity.finishedAt = nil
        }
        
        entity.lastUpdate = .now
        
        if synced {
            entity.progressType = .localSynced
        } else {
            entity.progressType = .localCached
        }
        
        try? entity.modelContext?.save()
        ProgressEntity.updatedSubject.send(item.id)
    }
    
    func updateProgressEntity(itemID: ItemIdentifier, currentTime: TimeInterval, duration: TimeInterval, success: Bool? = nil) {
        let entity = progressEntity(itemID: itemID)
        
        entity.progress = currentTime / duration
        
        entity.currentTime = currentTime
        entity.duration = duration
        
        if entity.startedAt == nil {
            entity.startedAt = .now
        }
        
        entity.lastUpdate = .now
        
        if entity.progress >= 1 {
            entity.finishedAt = .now
        }
        
        if let success {
            entity.progressType = success ? .localSynced : .localCached
        }
        
        try? entity.modelContext?.save()
        ProgressEntity.updatedSubject.send(itemID)
    }
}
