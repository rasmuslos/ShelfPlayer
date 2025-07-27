//
//  PlaybackReporter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import OSLog
import RFNotifications
import ShelfPlayerKit

#if canImport(UIKit)
import UIKit
#endif

final actor PlaybackReporter {
    nonisolated let logger = Logger(subsystem: "io.rfk.shelfplayerKit", category: "PlaybackReporter")
    
    private let itemID: ItemIdentifier
    
    private let sessionID: String?
    private var localSessionID: UUID?
    
    private var startTime: TimeInterval
    
    private var duration: TimeInterval?
    private var currentTime: TimeInterval?
    
    private var lastTimeSpendListeningCalculation: Date?
    private var accumulatedTimeSpendListening: TimeInterval = 0
    
    private var lastUpdate: Date
    private var isFinished: Bool
    
    private(set) var accumulatedServerReportedTimeListening: TimeInterval = 0
    
    init(itemID: ItemIdentifier, startTime: TimeInterval, sessionID: String?) {
        self.sessionID = sessionID
        self.itemID = itemID
        
        self.startTime = startTime
        
        lastUpdate = .now.advanced(by: -27)
        
        isFinished = false
        
        RFNotification[.finalizePlaybackReporting].subscribe { [weak self] in
            Task {
                await self?.finalize(currentTime: nil)
            }
        }
    }
    
    func didStartPlaying(at time: TimeInterval) {
        self.currentTime = time
        update()
    }
    
    func update(duration: TimeInterval) {
        self.duration = duration
    }
    func update(currentTime: TimeInterval) {
        self.currentTime = currentTime
        updateIfNeeded()
    }
    
    func didChangePlayState(isPlaying: Bool) {
        if isPlaying {
            if let lastTimeSpendListeningCalculation {
                logger.warning("Time spent listening is not accurate | current: \(Date().timeIntervalSince(lastTimeSpendListeningCalculation)) accumulated: \(self.accumulatedTimeSpendListening)")
            }
            
            lastTimeSpendListeningCalculation = .now
        } else {
            if let delta = lastTimeSpendListeningCalculation?.distance(to: .now) {
                lastTimeSpendListeningCalculation = nil
                accumulatedTimeSpendListening += delta
            } else {
                logger.warning("Could not calculate time spent listening")
            }
        }
        
        update()
    }
    
    func finalize(currentTime: TimeInterval?) async {
        guard !isFinished else {
            logger.warning("Attempt to finalize playback reporter after being already finalized")
            return
        }
        
        isFinished = true
        
        if let currentTime {
            self.currentTime = currentTime
        }
        
        await update(force: true)
        
        #if canImport(UIKit)
        let task = await UIApplication.shared.beginBackgroundTask(withName: "PlaybackReporter::finalize")
        #endif
        
        if let localSessionID {
            do {
                try await PersistenceManager.shared.session.closeLocalPlaybackSession(sessionID: localSessionID)
            } catch {
                logger.error("Failed to close local playback session: \(error)")
            }
        }
        
        if let sessionID, let duration, let currentTime {
            do {
                try await ABSClient[itemID.connectionID].closeSession(sessionID: sessionID, currentTime: currentTime, duration: duration, timeListened: 0)
                Defaults[.openPlaybackSessions].removeAll { $0.itemID == itemID && $0.sessionID == sessionID }
            } catch {
                logger.error("Failed to close session: \(error)")
            }
        }
        
        #if canImport(UIKit)
        await UIApplication.shared.endBackgroundTask(task)
        #endif
    }
}

private extension PlaybackReporter {
    func updateIfNeeded() {
        guard lastUpdate.distance(to: .now) > 30  else {
            return
        }
        
        update()
    }
    func update() {
        Task {
            await update()
        }
    }
    func update(force: Bool = false) async {
        // No async operations here
        
        guard (!isFinished || force) else {
            logger.warning("Attempt to update playback reporter after finalized")
            return
        }
        
        guard let duration, let currentTime else {
            return
        }
        
        let timeListened: TimeInterval
        
        if let delta = lastTimeSpendListeningCalculation?.distance(to: .now) {
            timeListened = accumulatedTimeSpendListening + delta
            lastTimeSpendListeningCalculation = .now
        } else {
            timeListened = accumulatedTimeSpendListening
        }
        
        accumulatedTimeSpendListening = 0
        lastUpdate = .now
        
        // Async operations (suspension) begins here
        
        var updateLocalSession = true
        
        do {
            if let sessionID {
                try await ABSClient[itemID.connectionID].syncSession(sessionID: sessionID, currentTime: currentTime, duration: duration, timeListened: timeListened)
                updateLocalSession = false
                
                accumulatedServerReportedTimeListening += timeListened
                await RFNotification[.cachedTimeSpendListeningChanged].send()
            }
        } catch {
            logger.warning("Failed to update session: \(error). Update local session instead.")
        }
        
        if updateLocalSession {
            do {
                if let localSessionID {
                    try await PersistenceManager.shared.session.updateLocalPlaybackSession(sessionID: localSessionID, currentTime: currentTime, duration: duration, timeListened: timeListened)
                } else {
                    localSessionID = try await PersistenceManager.shared.session.createLocalPlaybackSession(for: itemID, startTime: startTime, currentTime: currentTime, duration: duration, timeListened: timeListened)
                }
            } catch {
                logger.warning("Failed to update local session: \(error).")
            }
        }
        
        do {
            try await PersistenceManager.shared.progress.update(itemID, currentTime: currentTime, duration: duration, notifyServer: false)
        } catch {
            logger.warning("Cannot update progress: \(error).")
        }
    }
}
