//
//  SessionSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Combine
import Foundation
import SwiftData
import OSLog

typealias PersistedPlaybackSession = ShelfPlayerSchema.PersistedPlaybackSession

extension PersistenceManager {
    @ModelActor
    public final actor SessionSubsystem {
        public final class EventSource: @unchecked Sendable {
            public let cachedTimeSpendListeningChanged = PassthroughSubject<Void, Never>()
            public let synchronizedPlaybackSessions = PassthroughSubject<Void, Never>()

            init() {}
        }

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "SessionSubsystem")
        public nonisolated let events = EventSource()

        subscript(sessionID: UUID) -> PersistedPlaybackSession? {
            get throws {
                var descriptor = FetchDescriptor<PersistedPlaybackSession>(predicate: #Predicate { $0.id == sessionID })
                descriptor.fetchLimit = 1

                return try modelContext.fetch(descriptor).first
            }
        }

        func remove(itemID: ItemIdentifier) async {
            logger.info("Attempting early sync before removing sessions for \(itemID, privacy: .public)")

            do {
                try await attemptSync(connectionID: itemID.connectionID, early: true)
            } catch {
                logger.error("Sync failed while removing related sessions to itemID \(itemID, privacy: .public): \(error, privacy: .public)")
            }

            let description = itemID.description

            do {
                try modelContext.delete(model: PersistedPlaybackSession.self, where: #Predicate {
                    $0._itemID == description
                })
                try modelContext.save()
            } catch {
                logger.error("Failed to remove related sessions to itemID \(itemID): \(error)")
            }

            Task { @MainActor in
                self.events.cachedTimeSpendListeningChanged.send()
            }
        }
        func remove(connectionID: ItemIdentifier.ConnectionID) {
            do {
                try modelContext.delete(model: PersistedPlaybackSession.self, where: #Predicate {
                    $0._itemID.contains(connectionID)
                })
                try modelContext.save()
            } catch {
                logger.error("Failed to remove related sessions to connection \(connectionID): \(error)")
            }

            Task { @MainActor in
                self.events.cachedTimeSpendListeningChanged.send()
            }
        }
    }
}

public extension PersistenceManager.SessionSubsystem {
    func totalUnreportedTimeSpentListening() throws -> TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let sessions = try modelContext.fetch(FetchDescriptor<PersistedPlaybackSession>(predicate: #Predicate {
            $0.started >= startOfDay
        }))

        return sessions.reduce(0) { $0 + $1.timeListened }
    }

    func createLocalPlaybackSession(for itemID: ItemIdentifier, startTime: TimeInterval, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) throws -> UUID {
        let session = PersistedPlaybackSession(itemID: itemID,
                                               duration: duration,
                                               currentTime: currentTime,
                                               startTime: startTime,
                                               timeListened: timeListened)

        modelContext.insert(session)
        try modelContext.save()

        Task { @MainActor in
            self.events.cachedTimeSpendListeningChanged.send()
        }

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

        Task { @MainActor in
            self.events.cachedTimeSpendListeningChanged.send()
        }
    }
    func closeLocalPlaybackSession(sessionID: UUID) throws {
        guard let session = try self[sessionID] else {
            throw PersistenceError.missing
        }

        session.eligibleForEarlySync = true

        try modelContext.save()
    }

    func attemptSync(connectionID: ItemIdentifier.ConnectionID, early: Bool) async throws {
        let sessions = try modelContext.fetch(FetchDescriptor<PersistedPlaybackSession>(predicate: #Predicate { $0._itemID.contains(connectionID) }))
            .filter { $0.itemID.connectionID == connectionID }

        guard !sessions.isEmpty else {
            return
        }

        for session in sessions {
            do {
                try await ABSClient[session.itemID.connectionID].createListeningSession(itemID: session.itemID, timeListened: session.timeListened, startTime: session.startTime, currentTime: session.currentTime, started: session.started, updated: session.lastUpdated)
                modelContext.delete(session)
            } catch APIClientError.invalidResponseCode(let code) {
                logger.warning("Server responded with an invalid response \(code) code while syncing session. Deleting \(session.id)")
                modelContext.delete(session)
            } catch {
                logger.error("Failed to synchronize session: \(session.id)")
            }
        }

        try modelContext.save()

        await MainActor.run {
            events.synchronizedPlaybackSessions.send()
            events.cachedTimeSpendListeningChanged.send()
        }
    }
}
