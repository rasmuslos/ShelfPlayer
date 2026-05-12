//
//  ListeningGoalSubsystem.swift
//  ShelfPlayerKit
//

import Combine
import Foundation
import OSLog
import SwiftData

typealias PersistedListeningDay = ShelfPlayerSchema.PersistedListeningDay

extension PersistenceManager {
    public final actor ListeningGoalSubsystem: ModelActor {
        public final class EventSource: @unchecked Sendable {
            public let didCapture = PassthroughSubject<ItemIdentifier.ConnectionID, Never>()

            init() {}
        }

        public let modelExecutor: any SwiftData.ModelExecutor
        public let modelContainer: SwiftData.ModelContainer

        let logger: Logger
        public nonisolated let events = EventSource()

        init(modelContainer: SwiftData.ModelContainer) {
            let modelContext = ModelContext(modelContainer)

            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer

            self.logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListeningGoal")
        }
    }
}

public extension PersistenceManager.ListeningGoalSubsystem {
    /// Pull listening stats and lock every day prior to today.
    ///
    /// ABS attributes a session's full `timeListening` to the date the session
    /// was *opened*, not when the time elapsed. So a session that runs from
    /// 23:30 → 01:30 piles all 2h onto day-1; day-2 stays at zero. Worse, if
    /// the user keeps listening past midnight on a session created the day
    /// before, that day's value keeps inflating. To get a stable historical
    /// record we capture each day exactly once — the first time we observe
    /// it as no longer being today (in the user's local zone) — and refuse
    /// to overwrite it on later snapshots.
    func captureCompletedDays(connectionID: ItemIdentifier.ConnectionID) async throws {
        let stats = try await ABSClient[connectionID].listeningStats()
        try await capture(stats: stats, connectionID: connectionID)
    }

    func capture(stats: ListeningStatsPayload, connectionID: ItemIdentifier.ConnectionID) async throws {
        let formatter = Self.dayKeyFormatter
        let calendar = Calendar.current
        let todayKey = formatter.string(from: .now)
        let today = calendar.startOfDay(for: .now)

        var captured = 0

        for (dayKey, seconds) in stats.days {
            guard dayKey != todayKey else { continue }
            guard let date = formatter.date(from: dayKey),
                  calendar.startOfDay(for: date) < today else { continue }
            guard seconds > 0 else { continue }

            if try upsertIfMissing(connectionID: connectionID, dayKey: dayKey, seconds: seconds) {
                captured += 1
            }
        }

        if captured > 0 {
            try modelContext.save()
            events.didCapture.send(connectionID)
        }
    }

    /// Historical seconds for a connection, keyed by start-of-day Date.
    /// Excludes today.
    func historicalDays(connectionID: ItemIdentifier.ConnectionID) -> [Date: Double] {
        let descriptor = FetchDescriptor<PersistedListeningDay>(predicate: #Predicate {
            $0.connectionID == connectionID
        })

        guard let rows = try? modelContext.fetch(descriptor) else { return [:] }
        return aggregate(rows)
    }

    /// Historical seconds aggregated across every connection.
    func historicalDays() -> [Date: Double] {
        guard let rows = try? modelContext.fetch(FetchDescriptor<PersistedListeningDay>()) else { return [:] }
        return aggregate(rows)
    }

    func remove(connectionID: ItemIdentifier.ConnectionID) {
        do {
            try modelContext.delete(model: PersistedListeningDay.self, where: #Predicate {
                $0.connectionID == connectionID
            })
            try modelContext.save()
        } catch {
            logger.error("Failed to remove listening days for connection \(connectionID, privacy: .public): \(error, privacy: .public)")
        }
    }
}

private extension PersistenceManager.ListeningGoalSubsystem {
    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    func upsertIfMissing(connectionID: String, dayKey: String, seconds: Double) throws -> Bool {
        let composite = "\(connectionID)::\(dayKey)"
        let descriptor = FetchDescriptor<PersistedListeningDay>(predicate: #Predicate {
            $0.compositeKey == composite
        })

        if (try modelContext.fetch(descriptor).first) != nil {
            return false
        }

        modelContext.insert(PersistedListeningDay(connectionID: connectionID, dayKey: dayKey, seconds: seconds))
        return true
    }

    func aggregate(_ rows: [PersistedListeningDay]) -> [Date: Double] {
        let formatter = Self.dayKeyFormatter
        let calendar = Calendar.current

        var result: [Date: Double] = [:]
        for row in rows {
            guard let date = formatter.date(from: row.dayKey) else { continue }
            let start = calendar.startOfDay(for: date)
            result[start, default: 0] += row.seconds
        }
        return result
    }
}
