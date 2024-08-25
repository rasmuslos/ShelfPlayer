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
    func play(_ item: PlayableItem) async throws {
        stop()
        try await start(item)
    }
    func queue(_ item: PlayableItem) {
        if self.item == nil && queue.isEmpty {
            Task {
                try await play(item)
            }
            
            return
        }
        
        queue.append(item)
    }
    
    func stop() {
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
    }
    
    func seek(to: Double, inCurrentChapter: Bool = false) async {
        var to = to
        
        if to < 0 {
            await seek(to: 0, inCurrentChapter: inCurrentChapter)
            return
        }
        
        if inCurrentChapter, let chapter {
            to += chapter.start
        }
        
        if itemDuration != 0 && to >= itemDuration {
            playbackReporter?.reportProgress(currentTime: itemDuration, duration: itemDuration)
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
        
        playbackReporter?.reportProgress(currentTime: itemCurrentTime, duration: itemDuration)
        
        updateChapterIndex()
        updateNowPlayingWidget()
        
        NotificationCenter.default.post(name: AudioPlayer.timeDidChangeNotification, object: nil)
    }
}

internal extension AudioPlayer {
    func start(_ item: PlayableItem) async throws {
        let startTime: Double
        self.item = item
        
        do {
            startTime = try await retrievePlaybackSession()
        } catch {
            self.item = nil
            throw error
        }
        
        tracks.sort()
        chapters.sort()
        
        if let episode = item as? Episode {
            playbackRate = OfflineManager.shared.playbackSpeed(for: episode.podcastId, episodeID: episode.id)
        } else {
            playbackRate = OfflineManager.shared.playbackSpeed(for: item.id, episodeID: nil)
        }
        
        updateAudioSession(active: true)
        updateBookmarkCommand(active: item as? Audiobook != nil)
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
        
        try await start(queue.removeFirst())
    }
    func itemDidFinish(_ item: PlayableItem) {
        if let episode = item as? Episode {
            OfflineManager.shared.removePlaybackSpeedOverride(for: episode.podcastId, episodeID: episode.id)
        } else {
            OfflineManager.shared.removePlaybackSpeedOverride(for: item.id, episodeID: nil)
        }
            
        #if canImport(SPOfflineExtended)
        if Defaults[.deleteFinishedDownloads] {
            if let episode = item as? Episode {
                OfflineManager.shared.remove(episodeId: episode.id)
            } else {
                OfflineManager.shared.remove(audiobookId: item.id)
            }
        }
        #endif
    }
}
