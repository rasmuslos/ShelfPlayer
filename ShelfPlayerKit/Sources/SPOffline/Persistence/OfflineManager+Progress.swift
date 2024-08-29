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
    func progressEntities() throws -> [ItemProgress] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<ItemProgress>(sortBy: [SortDescriptor(\.lastUpdate)])
        
        return try context.fetch(descriptor)
    }
    
    func progressEntity(itemId: String, episodeId: String?) -> ItemProgress {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let entity = progressEntity(itemId: itemId, episodeId: episodeId, context: context) {
            return entity
        }
        
        let progress = ItemProgress(
            id: "tmp_\(episodeId ?? itemId)",
            itemId: itemId,
            episodeId: episodeId,
            duration: 0,
            currentTime: 0,
            progress: 0,
            startedAt: Date(),
            lastUpdate: Date(),
            progressType: .localSynced)
        
        context.insert(progress)
        try? context.save()
        
        return progress
    }
    
    func deleteProgressEntity(id: String) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        try context.delete(model: ItemProgress.self, where: #Predicate { $0.id == id })
        try context.save()
    }
    
    func syncCachedProgressEntities() async throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let cached = try OfflineManager.shared.progressEntities(type: .localCached, context: context)
        
        for progress in cached {
            try await AudiobookshelfClient.shared.updateProgress(itemId: progress.itemId, episodeId: progress.episodeId, currentTime: progress.currentTime, duration: progress.duration)
            updateProgressType(.localSynced, itemId: progress.itemId, episodeId: progress.episodeId)
        }
    }
    
    func updateProgressType(_ type: ItemProgress.ProgressType, itemId: String, episodeId: String?) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let entity = progressEntity(itemId: itemId, episodeId: episodeId, context: context)
        
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
                
                let existing = progressEntity(itemId: mediaProgress.libraryItemId, episodeId: mediaProgress.episodeId, context: context)
                
                if let existing = existing {
                    if Int64(existing.lastUpdate.timeIntervalSince1970 * 1000) < mediaProgress.lastUpdate {
                        logger.info("Updating progress: \(existing.id)")
                        
                        existing.duration = mediaProgress.duration
                        existing.currentTime = mediaProgress.currentTime
                        existing.progress = mediaProgress.progress
                        
                        existing.startedAt = Date(timeIntervalSince1970: Double(mediaProgress.startedAt) / 1000)
                        existing.lastUpdate = Date(timeIntervalSince1970: Double(mediaProgress.lastUpdate) / 1000)
                    }
                } else {
                    logger.info("Creating progress: \(mediaProgress.id)")
                    
                    let progress = ItemProgress(
                        id: mediaProgress.id,
                        itemId: mediaProgress.libraryItemId,
                        episodeId: mediaProgress.episodeId,
                        duration: mediaProgress.duration,
                        currentTime: mediaProgress.currentTime,
                        progress: mediaProgress.progress,
                        startedAt: Date(timeIntervalSince1970: Double(mediaProgress.startedAt) / 1000),
                        lastUpdate: Date(timeIntervalSince1970: Double(mediaProgress.lastUpdate) / 1000),
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
    func progressEntity(itemId: String, episodeId: String?, context: ModelContext) -> ItemProgress? {
        var descriptor: FetchDescriptor<ItemProgress>
        
        if let episodeId = episodeId {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.episodeId == episodeId })
        } else {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.itemId == itemId })
        }
        
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
    
    func progressEntities(type: ItemProgress.ProgressType, context: ModelContext) throws -> [ItemProgress] {
        try context.fetch(.init()).filter { $0.progressType == type }
    }
}

// MARK: Public (Higher order)

public extension OfflineManager {
    func progressEntity(item: Item) -> ItemProgress {
        if let episode = item as? Episode {
            return progressEntity(itemId: episode.podcastId, episodeId: episode.id)
        } else {
            return progressEntity(itemId: item.id, episodeId: nil)
        }
    }
    
    func deleteProgressEntities() throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
            
        try context.delete(model: ItemProgress.self)
        try context.save()
    }
    
    func deleteProgressEntities(type: ItemProgress.ProgressType, context: ModelContext) throws {
        for entity in try progressEntities(type: type, context: context) {
            context.delete(entity)
        }
    }
    
    func finished(_ finished: Bool, item: Item) {
        let entity = progressEntity(item: item)
        
        if finished {
            entity.progress = 1
            entity.currentTime = entity.duration
        } else {
            entity.progress = 0
            entity.currentTime = 0
        }
        
        entity.lastUpdate = Date()
        entity.progressType = .localSynced
        
        try? entity.modelContext?.save()
    }
    
    @MainActor
    func updateProgressEntity(itemId: String, episodeId: String?, currentTime: TimeInterval, duration: TimeInterval, success: Bool) {
        let entity = OfflineManager.shared.progressEntity(itemId: itemId, episodeId: episodeId)
        
        entity.currentTime = currentTime
        entity.duration = duration
        entity.progress = currentTime / duration
        entity.lastUpdate = Date()
        entity.progressType = success ? .localSynced : .localCached
        
        try? entity.modelContext?.save()
    }
}
