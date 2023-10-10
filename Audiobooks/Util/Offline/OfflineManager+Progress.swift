//
//  OfflineManager+Progress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData

// MARK: Import

extension OfflineManager {
    @MainActor
    func importSessions(_ sessions: [AudiobookshelfClient.MediaPorgress]) async {
        sessions.forEach { session in
            let existing: OfflineProgress?
            
            if let episodeId = session.episodeId {
                existing = getProgress(episodeId: episodeId)
            } else {
                existing = getProgress(id: session.id)
            }
            
            if let existing = existing {
                existing.duration = session.duration
                existing.currentTime = session.currentTime
                existing.progress = session.progress
                
                existing.startedAt = Date(timeIntervalSince1970: Double(session.startedAt) / 1000)
                existing.lastUpdate = Date(timeIntervalSince1970: Double(session.lastUpdate) / 1000)
            } else {
                let progress = OfflineProgress(
                    id: session.id,
                    itemId: session.libraryItemId,
                    additionalId: session.episodeId,
                    duration: session.duration,
                    currentTime: session.currentTime,
                    progress: session.progress,
                    startedAt: Date(timeIntervalSince1970: Double(session.startedAt) / 1000),
                    lastUpdate: Date(timeIntervalSince1970: Double(session.lastUpdate) / 1000),
                    progressType: .receivedFromServer)
                
                PersistenceManager.shared.modelContainer.mainContext.insert(progress)
            }
        }
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getProgress(id: String) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.itemId == id })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    @MainActor
    func getProgress(episodeId: String) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.additionalId == episodeId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getProgress(item: Item) -> OfflineProgress? {
        if let episode = item as? Episode {
            return getProgress(episodeId: episode.id)
        } else {
            return getProgress(id: item.id)
        }
    }
    
    @MainActor
    func getAllProgressEntities() throws -> [OfflineProgress] {
        let descriptor = FetchDescriptor<OfflineProgress>(sortBy: [SortDescriptor(\.lastUpdate)])
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
    }
}

// MARK: Set

extension OfflineManager {
    @MainActor
    func setProgress(item: Item, finished: Bool) {
        if let progress = getProgress(item: item) {
            if finished {
                progress.progress = 1
                progress.currentTime = progress.duration
            } else {
                progress.progress = 0
                progress.currentTime = 0
            }
        }
    }
}

// MARK: Delete

extension OfflineManager {
    @MainActor
    func deleteStoredProgress() {
        let all = try! getAllProgressEntities()
        all.forEach {
            PersistenceManager.shared.modelContainer.mainContext.delete($0)
        }
    }
}

// MARK: Tmp progress

extension OfflineManager {
    @MainActor
    func getOrCreateProgress(itemId: String, episodeId: String?) -> OfflineProgress {
        var progress: OfflineProgress!
        
        if let episodeId = episodeId {
            if let episode = getProgress(episodeId: episodeId) {
                return episode
            } else {
                progress = OfflineProgress(
                    id: "tmp_\(episodeId)",
                    itemId: itemId, 
                    additionalId: episodeId,
                    duration: 0,
                    currentTime: 0,
                    progress: 0,
                    startedAt: Date(),
                    lastUpdate: Date(),
                    progressType: .localSynced)
            }
        } else {
            if let progress = getProgress(id: itemId) {
                return progress
            } else {
                progress = OfflineProgress(
                    id: "tmp_\(itemId)",
                    itemId: itemId,
                    additionalId: nil,
                    duration: 0,
                    currentTime: 0,
                    progress: 0,
                    startedAt: Date(),
                    lastUpdate: Date(),
                    progressType: .localSynced)
            }
        }
        
        PersistenceManager.shared.modelContainer.mainContext.insert(progress)
        return progress
    }
    
    @MainActor
    func getCachedProgress(type: OfflineProgress.ProgressType) async throws -> [OfflineProgress] {
        // i hate SwiftData for forcing me to write this inefficient abomination
        let descriptor = FetchDescriptor<OfflineProgress>()
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).filter { $0.progressType == type }
    }
    
    @MainActor
    func deleteSyncedProgress() async throws {
        let synced = try await getCachedProgress(type: .localSynced)
        for progress in synced {
            PersistenceManager.shared.modelContainer.mainContext.delete(progress)
        }
    }
}
