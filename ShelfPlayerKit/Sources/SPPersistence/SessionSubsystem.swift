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
    }
}

public extension PersistenceManager.SessionSubsystem {
    func createLocalPlaybackSession(for itemID: ItemIdentifier, startTime: TimeInterval, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) throws -> UUID {
        let session = PersistedPlaybackSession(itemID: itemID,
                                               duration: duration,
                                               currentTime: currentTime,
                                               startTime: startTime,
                                               timeListened: timeListened)
        
        modelContext.insert(session)
        try modelContext.save()
        
        return session.id
    }
    func updateLocalPlaybackSession(sessionID: UUID, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) throws {
        guard let session = try self[sessionID] else {
            throw PersistenceError.missing
        }
        
        session.duration = duration
        session.currentTime = currentTime
        session.timeListened += timeListened
        
        session.lastUpdated = .now
        
        try modelContext.save()
    }
    func closeLocalPlaybackSession(sessionID: UUID) throws {
        guard let session = try self[sessionID] else {
            throw PersistenceError.missing
        }
        
        session.eligibleForEarlySync = true
        
        try modelContext.save()
    }
    
    func attemptSync(early: Bool) async throws {
        let descriptor: FetchDescriptor<PersistedPlaybackSession>
        
        if early {
            descriptor = FetchDescriptor<PersistedPlaybackSession>(predicate: #Predicate { $0.eligibleForEarlySync })
        } else {
            descriptor = FetchDescriptor<PersistedPlaybackSession>()
        }
        
        // try modelContext.enumerate(descriptor) { session in
        
        let sessions = try modelContext.fetch(descriptor)
        
        for session in sessions {
            try await ABSClient[session.itemID.connectionID].createListeningSession(itemID: session.itemID, timeListened: session.timeListened, startTime: session.startTime, currentTime: session.currentTime, started: session.started, updated: session.lastUpdated)
            modelContext.delete(session)
        }
        
        try modelContext.save()
    }
}
