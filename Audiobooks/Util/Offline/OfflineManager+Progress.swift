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
            if let existing = getProgress(id: session.id, additionalId: session.episodeId) {
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
                    lastUpdate: Date(timeIntervalSince1970: Double(session.lastUpdate) / 1000))
                
                PersistenceManager.shared.modelContainer.mainContext.insert(progress)
            }
        }
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getProgress(id: String, additionalId: String? = nil) -> OfflineProgress? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineProgress> { $0.itemId == id && $0.additionalId == additionalId })
        descriptor.fetchLimit = 1
        
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getProgress(item: Item) -> OfflineProgress? {
        getProgress(id: item.id, additionalId: item.additionalId)
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
