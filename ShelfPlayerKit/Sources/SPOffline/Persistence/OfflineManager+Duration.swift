//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.04.24.
//

import Foundation
import SwiftData
import SPBase

public extension OfflineManager {
    @MainActor
    func getPlaybackDurationTracker(itemId: String, episodeId: String?) -> PlaybackDuration {
        let id = UUID().uuidString
        let tracker = PlaybackDuration(id: id, itemId: itemId, episodeId: episodeId)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(tracker)
        return tracker
    }
    
    @MainActor
    func attemptPlaybackDurationSync(tracker: PlaybackDuration) async throws {
        if tracker.startTime.isNaN {
            PersistenceManager.shared.modelContainer.mainContext.delete(tracker)
            return
        }
        
        let progressEntity = requireProgressEntity(itemId: tracker.itemId, episodeId: tracker.episodeId)
        
        try await AudiobookshelfClient.shared.createSession(
            itemId: tracker.itemId,
            episodeId: tracker.episodeId,
            id: tracker.id,
            timeListened: tracker.duration,
            startTime: tracker.startTime,
            currentTime: progressEntity.currentTime,
            started: tracker.started,
            updated: tracker.lastUpdate)
        
        PersistenceManager.shared.modelContainer.mainContext.delete(tracker)
        logger.info("Created session \(tracker.id)")
    }
    
    @MainActor
    func attemptPlaybackDurationSync() async throws {
        // can be ignored at startup
        // let descriptor = FetchDescriptor<PlaybackDuration>(predicate: #Predicate { $0.eligibleForSync == true })
        let descriptor = FetchDescriptor<PlaybackDuration>()
        let entities = try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor)
        
        for entity in entities {
            try await attemptPlaybackDurationSync(tracker: entity)
        }
    }
}
