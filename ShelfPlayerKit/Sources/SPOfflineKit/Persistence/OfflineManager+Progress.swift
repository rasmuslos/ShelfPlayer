//
//  OfflineManager+Progress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import SPBaseKit

extension OfflineManager {
    @MainActor
    func getProgressEntities() throws -> [OfflineProgress] {
        let descriptor = FetchDescriptor<OfflineProgress>(sortBy: [SortDescriptor(\.lastUpdate)])
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
    }
    @MainActor
    func getProgressEntities(type: OfflineProgress.ProgressType) async throws -> [OfflineProgress] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor()).filter { $0.progressType == type }
    }
    
    @MainActor
    func requireProgressEntity(itemId: String, episodeId: String?) -> OfflineProgress {
        if let episodeId = episodeId, let progress = getProgressEntity(episodeId: episodeId) {
            return progress
        } else if let progress = getProgressEntity(itemId: itemId) {
            return progress
        }
        
        let progress = OfflineProgress(
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
        NotificationCenter.default.post(name: Self.progressCreatedNotification, object: nil)
        
        return progress
    }
    
    @MainActor
    func requireProgressEntity(item: Item) -> OfflineProgress {
        if let episode = item as? Episode {
            return requireProgressEntity(itemId: episode.podcastId, episodeId: episode.id)
        }
        
        return requireProgressEntity(itemId: item.id, episodeId: nil)
    }
    
}

public extension OfflineManager {
    @MainActor
    func getProgressEntity(itemId: String) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.itemId == itemId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    @MainActor
    func getProgressEntity(episodeId: String) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.episodeId == episodeId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getProgressEntity(item: Item) -> OfflineProgress? {
        if let episode = item as? Episode {
            return getProgressEntity(episodeId: episode.id)
        } else {
            return getProgressEntity(itemId: item.id)
        }
    }
    
    @MainActor
    func deleteProgressEntities() {
        for entity in try! getProgressEntities() {
            PersistenceManager.shared.modelContainer.mainContext.delete(entity)
        }
    }
    
    @MainActor
    func deleteProgressEntities(type: OfflineProgress.ProgressType) async throws {
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
    
    func syncProgressEntities() async -> Bool {
        do {
            let start = Date.timeIntervalSinceReferenceDate
            let cached = try await OfflineManager.shared.getProgressEntities(type: .localCached)
            for progress in cached {
                try await AudiobookshelfClient.shared.updateMediaProgress(itemId: progress.itemId, episodeId: progress.episodeId, currentTime: progress.currentTime, duration: progress.duration)
                
                progress.progressType = .localSynced
            }
            logger.info("Synced progress to server (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            try await OfflineManager.shared.deleteProgressEntities(type: .localSynced)
            logger.info("Deleted synced progress (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            
            let sessions = try await AudiobookshelfClient.shared.authorize()
            try await Task<Void, Error> { @MainActor in
                for session in sessions {
                    let existing: OfflineProgress?
                    
                    if let episodeId = session.episodeId {
                        existing = getProgressEntity(episodeId: episodeId)
                    } else {
                        existing = getProgressEntity(itemId: session.libraryItemId)
                    }
                    
                    if let existing = existing {
                        if Int64(existing.lastUpdate.timeIntervalSince1970 * 1000) < session.lastUpdate {
                            logger.info("Updating progress: \(existing.id)")
                            
                            existing.duration = session.duration
                            existing.currentTime = session.currentTime
                            existing.progress = session.progress
                            
                            existing.startedAt = Date(timeIntervalSince1970: Double(session.startedAt) / 1000)
                            existing.lastUpdate = Date(timeIntervalSince1970: Double(session.lastUpdate) / 1000)
                        }
                    } else {
                        logger.info("Creating progress: \(session.id)")
                        
                        let progress = OfflineProgress(
                            id: session.id,
                            itemId: session.libraryItemId,
                            episodeId: session.episodeId,
                            duration: session.duration,
                            currentTime: session.currentTime,
                            progress: session.progress,
                            startedAt: Date(timeIntervalSince1970: Double(session.startedAt) / 1000),
                            lastUpdate: Date(timeIntervalSince1970: Double(session.lastUpdate) / 1000),
                            progressType: .receivedFromServer)
                        
                        PersistenceManager.shared.modelContainer.mainContext.insert(progress)
                    }
                }
            }.result.get()
            
            logger.info("Imported sessions (took \(Date.timeIntervalSinceReferenceDate - start)s)")
            return true
        } catch {
            print(error)
            return false
        }
    }
}
