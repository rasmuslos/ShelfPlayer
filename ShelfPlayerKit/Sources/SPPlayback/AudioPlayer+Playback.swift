//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Defaults
import Intents
import AVKit
import Defaults
import SPFoundation
import SPExtension
import SPOffline

public extension AudioPlayer {
    func play(_ item: PlayableItem, at seconds: TimeInterval? = nil, withoutPlaybackSession: Bool = false) async throws {
        stop(.newItem)
        
        try await start(item, at: seconds, withoutPlaybackSession: withoutPlaybackSession)
        
        Task {
            guard queue.isEmpty else {
                return
            }
            
            if item.type == .episode && Defaults[.queueNextEpisodes] {
                await queueNextEpisodes()
            } else if item.type == .audiobook && Defaults[.queueNextAudiobooksInSeries] {
                await queueNextAudiobooksInSeries()
            }
        }
    }
    
    func stop(_ reason: StopReason) {
        stops.append(.init(time: .now, reason: reason))
        
        buffering = true
        
        item = nil
        queue = []
        
        chapters = []
        currentChapterIndex = nil
        
        tracks = []
        currentTrackIndex = nil
        
        chapterTTL = 0
        
        lastPause = nil
        playbackReporter = nil
        
        Task {
            await clearNowPlayingMetadata()
        }
        
        audioPlayer.removeAllItems()
        
        NotificationCenter.default.post(name: Self.itemDidChangeNotification, object: nil)
        NotificationCenter.default.post(name: Self.queueDidChangeNotification, object: nil)
    }
    
    func seek(to: TimeInterval, inCurrentChapter: Bool = false) async {
        var to = to
        
        if to < 0 {
            await seek(to: 0, inCurrentChapter: inCurrentChapter)
            return
        }
        
        if inCurrentChapter, let chapter {
            to += chapter.start
        }
        
        if itemDuration != 0 && to >= itemDuration {
            Task {
                do {
                    try await advance(finished: true)
                } catch {
                    stop(.seekExceededDuration)
                }
            }
            
            return
        }
        
        guard let index = trackIndex(currentTime: to) else {
            logger.fault("Invalid seek position (\(to))")
            return
        }
        
        let track = tracks[index]
        
        if index == currentTrackIndex {
            await audioPlayer.seek(to: CMTime(seconds: to - track.offset, preferredTimescale: 1000))
        } else {
            guard let item = item else {
                return
            }
            let resume = playing
            
            audioPlayer.pause()
            audioPlayer.removeAllItems()
            
            audioPlayer.insert(avPlayerItem(item: item, track: track), after: nil)
            
            for queueTrack in queue(currentTime: to) {
                audioPlayer.insert(avPlayerItem(item: item, track: queueTrack), after: nil)
            }
            
            await audioPlayer.seek(to: CMTime(seconds: to - track.offset, preferredTimescale: 1000))
            
            currentTrackIndex = index
            playing = resume
        }
        
        playbackReporter?.reportProgress(currentTime: itemCurrentTime, duration: itemDuration, forceReport: true)
        
        updateChapterIndex()
        await updateNowPlayingWidget()
        
        NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
    }
    
    func skipForwards() {
        Task {
            await skipForwards()
        }
    }
    func skipForwards() async {
        await seek(to: itemCurrentTime + .init(skipForwardsInterval))
        NotificationCenter.default.post(name: Self.forwardsNotification, object: nil)
    }
    
    func skipBackwards() {
        Task {
            await skipBackwards()
        }
    }
    func skipBackwards() async {
        await seek(to: itemCurrentTime - .init(skipBackwardsInterval))
        NotificationCenter.default.post(name: Self.backwardsNotification, object: nil)
    }
}

internal extension AudioPlayer {
    func start(_ item: PlayableItem, at seconds: Double? = nil, withoutPlaybackSession: Bool = false) async throws {
        buffering = true
        
        let startTime: TimeInterval
        self.item = item
        
        do {
            let suggestedStartTime = try await retrievePlaybackSession(offline: withoutPlaybackSession)
            startTime = seconds ?? suggestedStartTime
        } catch {
            self.item = nil
            throw error
        }
        
        tracks.sort()
        chapters.sort()
        
        playbackRate = OfflineManager.shared.playbackSpeed(for: item.identifiers.itemID, episodeID: item.identifiers.episodeID)
        
        updateAudioSession(active: true)
        updateBookmarkCommand(active: item.type == .audiobook)
        await populateNowPlayingWidgetMetadata()
        
        await seek(to: startTime)
        playing = true
        
        updateChapterIndex()
    }
    
    func advance(finished: Bool) async throws {
        if finished {
            playbackReporter?.reportProgress(currentTime: itemDuration, duration: itemDuration, forceReport: true)
            playbackReporter = nil
        }
        
        if queue.isEmpty {
            stop(.queueEmpty)
            return
        }
        
        buffering = true
        
        chapters = []
        currentChapterIndex = nil
        
        tracks = []
        currentTrackIndex = nil
        
        chapterTTL = 0
        
        lastPause = nil
        playbackReporter = nil
        
        await clearNowPlayingMetadata()
        audioPlayer.removeAllItems()
        
        let previous = item
        
        try await start(queue.removeFirst())
        
        if let previous {
            await previous.postFinishedNotification(finished: true)
        }
    }
}
