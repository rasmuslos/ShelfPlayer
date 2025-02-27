//
//  SessionSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import SwiftData
import SPFoundation

typealias PersistedPlaybackSession = SchemaV2.PersistedPlaybackSession

extension PersistenceManager {
    @ModelActor
    public final actor SessionSubsystem {
        subscript(sessionID: UUID) -> PersistedPlaybackSession? {
            get throws {
                var descriptor = FetchDescriptor<PersistedPlaybackSession>(predicate: #Predicate { $0.id == sessionID })
                descriptor.fetchLimit = 1
                
                return try modelContext.fetch(descriptor).first
            }
        }
        
        public func createLocalPlaybackSession(for itemID: ItemIdentifier, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) throws -> UUID {
            let session = PersistedPlaybackSession(itemID: itemID,
                                                   duration: duration,
                                                   currentTime: currentTime,
                                                   timeListened: timeListened)
            
            modelContext.insert(session)
            try modelContext.save()
            
            return session.id
        }
        public func updateLocalPlaybackSession(sessionID: UUID, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) throws {
            guard let session = try self[sessionID] else {
                throw PersistenceError.missing
            }
            
            session.duration = duration
            session.currentTime = currentTime
            session.timeListened += timeListened
            
            session.lastUpdated = .now
            
            try modelContext.save()
        }
        public func closeLocalPlaybackSession(sessionID: UUID) throws {
            guard let session = try self[sessionID] else {
                throw PersistenceError.missing
            }
            
            session.eligibleForEarlySync = true
            
            try modelContext.save()
        }
    }
}
