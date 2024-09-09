//
//  OfflineManager+Progress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import Defaults
import SPBase

extension OfflineManager {
    @MainActor
    func getProgressEntities() throws -> [ItemProgress] {
        let descriptor = FetchDescriptor<ItemProgress>(sortBy: [SortDescriptor(\.lastUpdate)])
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
    }
    @MainActor
    func getProgressEntities(type: ItemProgress.ProgressType) async throws -> [ItemProgress] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor()).filter { $0.progressType == type }
    }
    
    @MainActor
    func requireProgressEntity(itemId: String, episodeId: String?) -> ItemProgress {
        var descriptor: FetchDescriptor<ItemProgress>
        
        if let episodeId = episodeId {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.episodeId == episodeId })
        } else {
            descriptor = FetchDescriptor(predicate: #Predicate { $0.itemId == itemId })
        }
        
        descriptor.fetchLimit = 1
        if let entity = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
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
        
        PersistenceManager.shared.modelContainer.mainContext.insert(progress)
        return progress
    }
    
    @MainActor
    func deleteProgressEntity(id: String) throws {
        try PersistenceManager.shared.modelContainer.mainContext.delete(model: ItemProgress.self, where: #Predicate { $0.id == id })
    }
    
    func syncCachedProgressEntities() async throws {
        let cached = try await OfflineManager.shared.getProgressEntities(type: .localCached)
        
        for progress in cached {
            try await AudiobookshelfClient.shared.updateMediaProgress(itemId: progress.itemId, episodeId: progress.episodeId, currentTime: progress.currentTime, duration: progress.duration)
            progress.progressType = .localSynced
        }
    }
    
    func deleteSyncedProgressEntities() async throws {
        try await OfflineManager.shared.deleteProgressEntities(type: .localSynced)
    }
    
    func updateLocalProgressEntities(mediaProgress: [AudiobookshelfClient.MediaProgress]) async throws {
        try await Task<Void, Error> { @MainActor in
            var hideFromContinueListening = [Defaults.Keys.HideFromContinueListeningEntity]()
            
            try PersistenceManager.shared.modelContainer.mainContext.transaction {
                for mediaProgress in mediaProgress {
                    if mediaProgress.hideFromContinueListening {
                        hideFromContinueListening.append(.init(itemId: mediaProgress.libraryItemId, episodeId: mediaProgress.episodeId))
                    }
                    
                    let existing: ItemProgress?
                    var descriptor: FetchDescriptor<ItemProgress>
                    
                    if let episodeId = mediaProgress.episodeId {
                        descriptor = FetchDescriptor(predicate: #Predicate { $0.episodeId == episodeId })
                    } else {
                        descriptor = FetchDescriptor(predicate: #Predicate { $0.itemId == mediaProgress.libraryItemId })
                    }
                    
                    descriptor.fetchLimit = 1
                    existing = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
                    
                    if let existing = existing {
                        if Int64(existing.lastUpdate.timeIntervalSince1970 * 1000) < mediaProgress.lastUpdate {
                            logger.info("Updating progress: \(existing.id)")
                            
                            existing.duration = mediaProgress.duration ?? 0
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
                            duration: mediaProgress.duration ?? 0,
                            currentTime: mediaProgress.currentTime,
                            progress: mediaProgress.progress,
                            startedAt: Date(timeIntervalSince1970: Double(mediaProgress.startedAt) / 1000),
                            lastUpdate: Date(timeIntervalSince1970: Double(mediaProgress.lastUpdate) / 1000),
                            progressType: .receivedFromServer)
                        
                        PersistenceManager.shared.modelContainer.mainContext.insert(progress)
                    }
                }
            }
            
            Defaults[.hideFromContinueListening] = hideFromContinueListening
        }.result.get()
    }
}

public extension OfflineManager {
    @MainActor
    func requireProgressEntity(item: Item) -> ItemProgress {
        if let episode = item as? Episode {
            return requireProgressEntity(itemId: episode.podcastId, episodeId: episode.id)
        }
        
        return requireProgressEntity(itemId: item.id, episodeId: nil)
    }
    
    @MainActor
    func deleteProgressEntities() {
        for entity in try! getProgressEntities() {
            PersistenceManager.shared.modelContainer.mainContext.delete(entity)
        }
    }
    
    @MainActor
    func deleteProgressEntities(type: ItemProgress.ProgressType) async throws {
        for entity in try await getProgressEntities(type: type) {
            PersistenceManager.shared.modelContainer.mainContext.delete(entity)
        }
    }
    
    @MainActor
    func setProgress(item: Item, finished: Bool) {
        let progress = requireProgressEntity(item: item)
        
        if finished {
            progress.progress = 1
            progress.currentTime = progress.duration
        } else {
            progress.progress = 0
            progress.currentTime = 0
        }
        
        progress.lastUpdate = Date()
        progress.progressType = .localSynced
    }
    
    @MainActor
    func updateProgressEntity(itemId: String, episodeId: String?, currentTime: Double, duration: Double, success: Bool) {
        let progress = OfflineManager.shared.requireProgressEntity(itemId: itemId, episodeId: episodeId)
        
        progress.currentTime = currentTime
        progress.duration = duration
        progress.progress = currentTime / duration
        progress.lastUpdate = Date()
        progress.progressType = success ? .localSynced : .localCached
    }
}
