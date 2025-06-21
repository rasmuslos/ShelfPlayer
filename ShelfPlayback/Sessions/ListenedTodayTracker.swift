//
//  ListenedTodayTracker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import Foundation
import RFNotifications
import ShelfPlayerKit

@MainActor @Observable
public final class ListenedTodayTracker {
    @ObservableDefault(.listenTimeTarget) @ObservationIgnored
    public var listenTimeTarget: Int
    
    public private(set) var todaySessionLoader: SessionLoader!
    
    private(set) var cachedTimeSpendListening = 0.0
    private var timer: DispatchSourceTimer?
    
    private init() {
        todaySessionLoader = SessionLoader(filter: .today) {
            self.updateCachedTimeSpendListening()
        }
        
        RFNotification[.cachedTimeSpendListeningChanged].subscribe { [weak self] in
            self?.updateCachedTimeSpendListening()
        }
        
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
            
            let cachedSessions = try await PersistenceManager.shared.session.totalUnreportedTimeSpentListening()
            let pendingOpen = await AudioPlayer.shared.pendingTimeSpendListening ?? 0
            
            await MainActor.run {
                self.cachedTimeSpendListening = cachedSessions + pendingOpen
                RFNotification[.timeSpendListeningChanged].send(payload: totalMinutesListenedToday)
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

