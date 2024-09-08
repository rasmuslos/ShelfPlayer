//
//  PlaybackReporter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import Foundation
import Defaults
import SPFoundation
import SPNetwork
import SPOffline

#if canImport(SPOfflineExtended)
import SPOfflineExtended
#endif

internal final class PlaybackReporter {
    private let itemId: String
    private let episodeId: String?
    
    private let playbackSessionId: String?
    private let listeningTimeTracker: OfflineListeningTimeTracker?
    
    private var duration: TimeInterval
    private var currentTime: TimeInterval
    
    private var lastUpdate: Date
    private var lastReport: Date
    
    internal init(itemId: String, episodeId: String?, playbackSessionId: String?) {
        self.itemId = itemId
        self.episodeId = episodeId
        self.playbackSessionId = playbackSessionId
        
        duration = .nan
        currentTime = .nan
        
        lastUpdate = .now
        lastReport = .now
        
        listeningTimeTracker = OfflineManager.shared.listeningTimeTracker(itemId: itemId, episodeId: episodeId)
    }
    
    deinit {
        Self.reportPlaybackStop(playbackSessionId: playbackSessionId,
                                playbackDurationTracker: listeningTimeTracker,
                                itemId: itemId,
                                episodeId: episodeId,
                                currentTime: currentTime,
                                duration: duration,
                                timeListened: timeListened())
    }
    
    enum ReportError: Error {
        case playbackSessionIdMissing
    }
}

internal extension PlaybackReporter {
    func reportProgress(currentTime: TimeInterval, duration: TimeInterval, forceReport: Bool = false) {
        updateTime(currentTime: currentTime, duration: duration)
        
        // report every 30 seconds
        if Int(currentTime) % 30 == 0 || forceReport {
            reportProgress()
            return
        }
        
        let duration = DateInterval(start: lastUpdate, end: .now).duration
        
        guard duration > 0.2 else {
            return
        }
        
        lastUpdate = .now
        
        Task {
            await OfflineManager.shared.updateProgressEntity(itemId: itemId, episodeId: episodeId, currentTime: self.currentTime, duration: self.duration)
        }
    }
    func reportProgress(playing: Bool, currentTime: TimeInterval, duration: TimeInterval) {
        updateTime(currentTime: currentTime, duration: duration)
        
        if playing {
            // Reset time listened when playing again (was running in the background)
            let _ = timeListened()
        } else {
            reportProgress()
        }
    }
}

private extension PlaybackReporter {
    func reportProgress() {
        if currentTime.isNaN || duration.isNaN {
            return
        }
        
        let timeListened = timeListened()
        
        Task { [self] in
            var success = true
            
            do {
                if let playbackSessionId {
                    try await AudiobookshelfClient.shared.reportUpdate(playbackSessionId: playbackSessionId,
                                                                       currentTime: currentTime,
                                                                       duration: duration,
                                                                       timeListened: timeListened)
                } else {
                    try await Self.reportWithoutPlaybackSession(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
                }
            } catch {
                listeningTimeTracker?.duration += timeListened
                listeningTimeTracker?.lastUpdate = Date()
                
                success = false
            }
            
            await OfflineManager.shared.updateProgressEntity(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration, success: success)
        }
    }
    
    func timeListened() -> TimeInterval {
        let duration = DateInterval(start: lastReport, end: .now).duration
        lastReport = .now
        
        guard duration.isFinite else {
            return 0
        }
        
        return duration
    }
    
    func updateTime(currentTime: TimeInterval, duration: TimeInterval) {
        if duration.isFinite && duration != 0 {
            self.duration = duration
        }
        
        if currentTime.isFinite && currentTime != 0 {
            self.currentTime = currentTime
            
            if listeningTimeTracker?.startTime.isNaN == true {
                listeningTimeTracker?.startTime = currentTime
            }
        }
    }
}

// MARK: Close

extension PlaybackReporter {
    private static func reportPlaybackStop(
        playbackSessionId: String?,
        playbackDurationTracker: OfflineListeningTimeTracker?,
        itemId: String,
        episodeId: String?,
        currentTime: TimeInterval,
        duration: TimeInterval,
        timeListened: TimeInterval) {
            if currentTime.isNaN || duration.isNaN {
                return
            }
            
            Task {
                var success = true
                
                do {
                    if let playbackSessionId {
                        try await AudiobookshelfClient.shared.reportClose(playbackSessionId: playbackSessionId, currentTime: currentTime, duration: duration, timeListened: timeListened)
                    } else {
                        try await Self.reportWithoutPlaybackSession(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
                    }
                } catch {
                    success = false
                }
                
                await OfflineManager.shared.updateProgressEntity(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration, success: success)
            }
            
            playbackDurationTracker?.duration += timeListened
            playbackDurationTracker?.lastUpdate = Date()
            playbackDurationTracker?.eligibleForSync = true
                    
            if let playbackDurationTracker {
                Task {
                    try? await OfflineManager.shared.attemptListeningTimeSync(tracker: playbackDurationTracker)
                }
            }
        }
    
    private static func reportWithoutPlaybackSession(itemId: String, episodeId: String?, currentTime: TimeInterval, duration: TimeInterval) async throws {
        try await AudiobookshelfClient.shared.updateProgress(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
    }
}
