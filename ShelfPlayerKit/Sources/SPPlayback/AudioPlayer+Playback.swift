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
    func play(_ item: PlayableItem, at seconds: TimeInterval? = nil, queue: [PlayableItem]) async throws {
        stop()
        
        try await start(item, at: seconds)
        self.queue = queue
    }
    
    func stop() {
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
        
        clearNowPlayingMetadata()
        
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
            playbackReporter?.reportProgress(currentTime: itemCurrentTime, duration: itemDuration, forceReport: true)
            stop()
            
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
        updateNowPlayingWidget()
        
        NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
    }
    
    func skipForwards() {
        Task {
            await skipForwards()
        }
    }
    func skipForwards() async {
        await seek(to: itemCurrentTime + .init(skipForwardsInterval))
    }
    
    func skipBackwards() {
        Task {
            await skipBackwards()
        }
    }
    func skipBackwards() async {
        await seek(to: itemCurrentTime - .init(skipBackwardsInterval))
    }
}

internal extension AudioPlayer {
    func start(_ item: PlayableItem, at seconds: Double? = nil) async throws {
        let startTime: TimeInterval
        self.item = item
        
        do {
            let suggestedStartTime = try await retrievePlaybackSession()
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
        populateNowPlayingWidgetMetadata()
        
        await seek(to: startTime)
        playing = true
        
        updateChapterIndex()
        
        Task {
            try await donateIntent()
        }
    }
    
    func advance() async throws {
        if queue.isEmpty {
            stop()
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
        
        clearNowPlayingMetadata()
        audioPlayer.removeAllItems()
        
        try await start(queue.removeFirst())
    }
    func itemDidFinish(_ item: PlayableItem) {
        OfflineManager.shared.removePlaybackSpeedOverride(for: item.identifiers.itemID, episodeID: item.identifiers.episodeID)
            
        #if canImport(SPOfflineExtended)
        if Defaults[.deleteFinishedDownloads] {
            if let episodeID = item.identifiers.episodeID {
                OfflineManager.shared.remove(episodeId: episodeID)
            } else {
                OfflineManager.shared.remove(audiobookId: item.identifiers.itemID)
            }
        }
        #endif
    }
}
