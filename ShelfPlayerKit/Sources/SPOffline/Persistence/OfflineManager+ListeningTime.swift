//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.04.24.
//

import Foundation
import SwiftData
import SPFoundation
import SPNetwork

// MARK: Public (Higher order)

public extension OfflineManager {
    func listeningTimeTracker(itemId: String, episodeId: String?) -> OfflineListeningTimeTracker {
        let id = UUID().uuidString
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let tracker = OfflineListeningTimeTracker(id: id, itemId: itemId, episodeId: episodeId)
        
        context.insert(tracker)
        try? context.save()
        
        return tracker
    }
    
    func attemptListeningTimeSync(tracker: OfflineListeningTimeTracker) async throws {
        if tracker.startTime.isNaN {
            delete(listeningTimeTracker: tracker)
            return
        }
        
        let progressEntity = requireProgressEntity(itemId: tracker.itemId, episodeId: tracker.episodeId)
        
        try await AudiobookshelfClient.shared.createListeningSession(
            itemId: tracker.itemId,
            episodeId: tracker.episodeId,
            id: tracker.id,
            timeListened: tracker.duration,
            startTime: tracker.startTime,
            currentTime: progressEntity.currentTime,
            started: tracker.started,
            updated: tracker.lastUpdate)
        
        delete(listeningTimeTracker: tracker)
        logger.info("Created session \(tracker.id)")
    }
    func delete(listeningTimeTracker: OfflineListeningTimeTracker) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        context.delete(listeningTimeTracker)
        try context.save()
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
