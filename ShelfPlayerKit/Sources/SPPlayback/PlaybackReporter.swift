//
//  PlaybackReporter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import OSLog
import Defaults
import RFNotifications
import SPFoundation
import SPPersistence

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
    
    private var lastUpdate: Date?
    private var isFinished: Bool
    
    private(set) var accumulatedServerReportedTimeListening: TimeInterval = 0
    
    init(itemID: ItemIdentifier, startTime: TimeInterval, sessionID: String?) {
        self.sessionID = sessionID
        self.itemID = itemID
        
        self.startTime = startTime
        
        isFinished = false
        
        RFNotification[.finalizePlaybackReporting].subscribe { [weak self] in
            Task {
                await self?.finalize()
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
    
    func finalize() {
        guard !isFinished else {
            logger.warning("Attempt to finalize playback reporter after being already finalized")
            return
        }
        
        update()
        isFinished = true
        
        if let duration, let currentTime {
            if duration - currentTime < 10 {
                self.currentTime = duration
                
                if Defaults[.removeFinishedDownloads] {
                    Task {
                        do {
                            try await PersistenceManager.shared.download.remove(itemID)
                        } catch {
                            logger.error("Failed to remove finished download: \(error)")
                        }
                    }
                }
            }
        }
        
        Task {
            let task = await UIApplication.shared.beginBackgroundTask(withName: "PlaybackReporter::finalize")
            
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
                } catch {
                    logger.error("Failed to close session: \(error)")
                }
            }
            
            await UIApplication.shared.endBackgroundTask(task)
        }
    }
}

private extension PlaybackReporter {
    func updateIfNeeded() {
        // Update once every minute
        if let lastUpdate, lastUpdate.distance(to: .now) > 60 {
            update()
        } else if lastUpdate == nil {
            update()
        }
    }
    func update() {
        guard !isFinished else {
            logger.warning("Attempt to update playback reporter after finalized")
            return
        }
        
        guard let duration, let currentTime else {
            return
        }
        
        let timeListened: TimeInterval
        
        if let delta = lastTimeSpendListeningCalculation?.distance(to: .now) {
            timeListened = accumulatedTimeSpendListening + delta
        } else {
            timeListened = accumulatedTimeSpendListening
        }
        
        accumulatedTimeSpendListening = 0
        lastTimeSpendListeningCalculation = .now
        lastUpdate = .now
        
        Task {
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
}
