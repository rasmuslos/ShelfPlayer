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

/// An object that reports playback progress to the ABS server or alternatively stores is for future syncing
internal final class PlaybackReporter {
    private let itemId: String
    private let episodeId: String?
    
    private let playbackSessionId: String?
    private let playbackDurationTracker: OfflineListeningTimeTracker?
    
    private var duration: Double
    private var currentTime: Double
    private var lastReportedTime: Double
    
    internal init(itemId: String, episodeId: String?, playbackSessionId: String?) {
        self.itemId = itemId
        self.episodeId = episodeId
        self.playbackSessionId = playbackSessionId
        
        duration = .nan
        currentTime = .nan
        lastReportedTime = Date.timeIntervalSinceReferenceDate
        
        if playbackSessionId == nil {
            playbackDurationTracker = OfflineManager.shared.listeningTimeTracker(itemId: itemId, episodeId: episodeId)
        } else {
            playbackDurationTracker = nil
        }
    }
    
    deinit {
        Self.reportPlaybackStop(playbackSessionId: playbackSessionId, playbackDurationTracker: playbackDurationTracker, itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration, timeListened: getTimeListened())
    }
}

internal extension PlaybackReporter {
    func reportProgress(currentTime: Double, duration: Double) {
        updateTime(currentTime: currentTime, duration: duration)
        
        // report every 30 seconds
        if Int(currentTime) % 30 == 0 {
            reportProgress()
        }
    }
    func reportProgress(playing: Bool, currentTime: Double, duration: Double) {
        updateTime(currentTime: currentTime, duration: duration)
        
        if playing {
            let _ = getTimeListened()
        } else {
            reportProgress()
        }
    }
}

// MARK: Report

private extension PlaybackReporter {
    func reportProgress() {
        if currentTime.isNaN || duration.isNaN {
            return
        }
        
        let timeListened = getTimeListened()
        
        Task.detached { [self] in
            var success = true
            
            Task.detached { @MainActor [self] in
                if let playbackDurationTracker = playbackDurationTracker {
                    playbackDurationTracker.duration += timeListened
                    playbackDurationTracker.lastUpdate = Date()
                }
            }
            
            do {
                if let playbackSessionId = playbackSessionId {
                    try await AudiobookshelfClient.shared.reportUpdate(playbackSessionId: playbackSessionId, currentTime: currentTime, duration: duration, timeListened: timeListened)
                } else {
                    try await Self.reportWithoutPlaybackSession(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
                }
            } catch {
                success = false
            }
            
            await OfflineManager.shared.updateProgressEntity(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration, success: success)
        }
    }
}

// MARK: Helper

fileprivate extension PlaybackReporter {
    func getTimeListened() -> Double {
        let timeListened = Date.timeIntervalSinceReferenceDate - lastReportedTime
        lastReportedTime = Date.timeIntervalSinceReferenceDate
        
        if !timeListened.isFinite {
            return 0
        }
        
        return timeListened
    }
    
    func updateTime(currentTime: Double, duration: Double) {
        if duration.isFinite && duration != 0 {
            self.duration = duration
        }
        
        if currentTime.isFinite && currentTime != 0 {
            self.currentTime = currentTime
            
            if playbackDurationTracker?.startTime.isNaN == true {
                playbackDurationTracker?.startTime = currentTime
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
        currentTime: Double,
        duration: Double,
        timeListened: Double) {
            if currentTime.isNaN || duration.isNaN {
                return
            }
            
            Task.detached {
                var success = true
                
                do {
                    if let playbackSessionId = playbackSessionId {
                        try await AudiobookshelfClient.shared.reportClose(playbackSessionId: playbackSessionId, currentTime: currentTime, duration: duration, timeListened: timeListened)
                    } else {
                        try await Self.reportWithoutPlaybackSession(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
                    }
                } catch {
                    success = false
                }
                
                await OfflineManager.shared.updateProgressEntity(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration, success: success)
            }
            
            if let playbackDurationTracker = playbackDurationTracker {
                Task.detached { @MainActor in
                    playbackDurationTracker.duration += timeListened
                    playbackDurationTracker.lastUpdate = Date()
                    playbackDurationTracker.eligibleForSync = true
                    
                    try? await OfflineManager.shared.attemptListeningTimeSync(tracker: playbackDurationTracker)
                }
            }
            
            if currentTime >= duration {
                Defaults.reset(.playbackSpeed(itemId: itemId, episodeId: episodeId))
                
                #if canImport(SPOfflineExtended)
                if Defaults[.deleteFinishedDownloads] {
                    if let episodeId = episodeId {
                        OfflineManager.shared.remove(episodeId: episodeId)
                    } else {
                        OfflineManager.shared.remove(audiobookId: itemId)
                    }
                }
                #endif
            }
        }
    
    private static func reportWithoutPlaybackSession(itemId: String, episodeId: String?, currentTime: Double, duration: Double) async throws {
        try await AudiobookshelfClient.shared.updateProgress(itemId: itemId, episodeId: episodeId, currentTime: currentTime, duration: duration)
    }
    
    enum ReportError: Error {
        case playbackSessionIdMissing
    }
}
