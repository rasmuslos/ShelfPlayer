//
//  ListenedTodayTracker.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Combine
import Foundation
import OSLog
import ShelfPlayerKit

@MainActor @Observable
public final class ListenedTodayTracker {
    nonisolated let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenedTodayTracker")

    public final class EventSource: @unchecked Sendable {
        public let timeSpendListeningChanged = PassthroughSubject<Int, Never>()

        init() {}
    }

    public var listenTimeTarget: Int {
        get { AppSettings.shared.listenTimeTarget }
        set { AppSettings.shared.listenTimeTarget = newValue }
    }

    public private(set) var todaySessionLoader: SessionLoader!
    public nonisolated let events = EventSource()

    private(set) var cachedTimeSpendListening = 0.0
    private var timer: DispatchSourceTimer?
    private var observerSubscriptions = Set<AnyCancellable>()

    private init() {
        todaySessionLoader = SessionLoader(filter: .today) {
            self.updateCachedTimeSpendListening()
        }

        todaySessionLoader.refresh()

        PersistenceManager.shared.session.events.cachedTimeSpendListeningChanged
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateCachedTimeSpendListening()
            }
            .store(in: &observerSubscriptions)
        AppEventSource.shared.scenePhaseDidChange
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                guard isActive else {
                    return
                }

                self?.refresh()
            }
            .store(in: &observerSubscriptions)

        scheduleResetTimer()
    }

    public var totalMinutesListenedToday: Int {
        Int((todaySessionLoader.totalTimeSpendListening + cachedTimeSpendListening) / 60)
    }

    public func refresh() {
        todaySessionLoader.refresh()
    }

    private nonisolated func updateCachedTimeSpendListening() {
        Task {
            guard await todaySessionLoader.isFinished else {
                return
            }

            do {
                let cachedSessions = try await PersistenceManager.shared.session.totalUnreportedTimeSpentListening()
                let pendingOpen = await AudioPlayer.shared.pendingTimeSpendListening ?? 0

                await MainActor.run {
                    self.cachedTimeSpendListening = cachedSessions + pendingOpen
                    self.events.timeSpendListeningChanged.send(totalMinutesListenedToday)
                }
            } catch {
                logger.error("Failed to update cached time spent listening: \(error)")
            }
        }
    }
    private func scheduleResetTimer() {
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer!.setEventHandler {
            self.refresh()
            self.scheduleResetTimer()
        }

        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        let timeIntervalToMidnight = Int(Date.now.distance(to: midnight))

        timer!.schedule(deadline: .now().advanced(by: .seconds(timeIntervalToMidnight)))
        timer!.activate()
    }

    public static let shared = ListenedTodayTracker()
}
