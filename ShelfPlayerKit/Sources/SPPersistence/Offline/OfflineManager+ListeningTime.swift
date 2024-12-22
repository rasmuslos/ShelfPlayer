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
        if tracker.startTime.isNaN || tracker.duration.isNaN || tracker.duration <= 5 {
            try remove(listeningTimeTracker: tracker)
            return
        }
        
        let progressEntity = progressEntity(itemID: .init(itemID: tracker.itemId, episodeID: tracker.episodeId))
        
        try await AudiobookshelfClient.shared.createListeningSession(
            itemId: tracker.itemId,
            episodeId: tracker.episodeId,
            id: tracker.id,
            timeListened: tracker.duration,
            startTime: tracker.startTime,
            currentTime: progressEntity.currentTime,
            started: tracker.started,
            updated: tracker.lastUpdate)
        
        try remove(listeningTimeTracker: tracker)
        logger.info("Created session \(tracker.id)")
    }
    func remove(listeningTimeTracker: OfflineListeningTimeTracker) throws {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        context.delete(listeningTimeTracker)
        try context.save()
    }
    
    func attemptListeningTimeSync() async throws {
        // can be ignored at startup
        // let descriptor = FetchDescriptor<PlaybackDuration>(predicate: #Predicate { $0.eligibleForSync == true })
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineListeningTimeTracker>()
        let entities = try context.fetch(descriptor)
        
        for entity in entities {
            try await attemptListeningTimeSync(tracker: entity)
        }
    }
}
