//
//  AudioPlayer.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import MediaPlayer
import Combine
import AVKit
import OSLog
import Defaults
import SPFoundation
import SPOffline

public final class AudioPlayer {
    internal var audioPlayer: AVQueuePlayer
    
    public var playing: Bool {
        get {
            audioPlayer.rate > 0
        }
        set {
            guard newValue != playing else {
                return
            }
            
            if newValue {
                Task {
                    if let lastPause = lastPause, lastPause.timeIntervalSince(Date()) <= -10 * 60 {
                        await seek(to: itemCurrentTime - 30)
                    }
                    
                    lastPause = nil
                    audioPlayer.play()
                    updateAudioSession(active: true)
                }
            } else {
                audioPlayer.pause()
                
                if Defaults[.smartRewind] {
                    lastPause = Date()
                }
            }
            
            updateNowPlayingWidget()
            
            NotificationCenter.default.post(name: AudioPlayer.playingDidChangeNotification, object: nil)
        }
    }
    var buffering: Bool {
        didSet {
            guard oldValue != buffering else {
                return
            }
            
            updateChapterIndex()
            
            NotificationCenter.default.post(name: AudioPlayer.bufferingDidChangeNotification, object: nil)
        }
    }
    
    var itemCurrentTime: Double {
        get {
            var seconds: Double
            
            if tracks.count == 1 {
                seconds = audioPlayer.currentTime().seconds
            } else if let currentTrackIndex {
                seconds = tracks[currentTrackIndex].offset
                seconds += audioPlayer.currentTime().seconds
            } else {
                seconds = 0
            }
            
            guard seconds.isFinite && !seconds.isNaN else {
                return 0
            }
            
            return seconds
        }
        set {
            Task {
                await seek(to: newValue)
            }
        }
    }
    var itemDuration: Double {
        let duration = tracks.reduce(0, { $0 + $1.duration })
        
        guard duration.isFinite && !duration.isNaN else {
            return 0
        }
        
        return duration
    }
    
    var chapterCurrentTime: Double {
        get {
            if let chapter {
                return itemCurrentTime - chapter.start
            } else {
                return itemCurrentTime
            }
        }
        set {
            Task {
                await seek(to: newValue, inCurrentChapter: true)
            }
        }
    }
    var chapterDuration: Double {
        if let chapter {
            return chapter.end - chapter.start
        } else {
            return itemDuration
        }
    }
    
    var volume: Float {
        get {
            systemVolume
        }
        set {
            guard newValue != volume else {
                return
            }
            
            Task { @MainActor in
                MPVolumeView.setVolume(newValue)
            }
            
            NotificationCenter.default.post(name: AudioPlayer.volumeDidChangeNotification, object: nil)
        }
    }
    
    var item: PlayableItem? {
        didSet {
            guard oldValue != item else {
                return
            }
            
            populateNowPlayingWidgetMetadata()
            NotificationCenter.default.post(name: AudioPlayer.itemDidChangeNotification, object: nil)
        }
    }
    var queue: [PlayableItem] {
        didSet {
            guard oldValue != queue else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.queueDidChangeNotification, object: nil)
        }
    }
    
    public internal(set) var currentChapterIndex: Int? {
        didSet {
            guard oldValue != currentChapterIndex else {
                return
            }
            
            updateNowPlayingTitle()
            NotificationCenter.default.post(name: AudioPlayer.chapterDidChangeNotification, object: nil)
        }
    }
    public internal(set) var chapters: [PlayableItem.Chapter]
    
    public var playbackRate: Float {
        didSet {
            audioPlayer.defaultRate = playbackRate
            
            if let item {
                if let episode = item as? Episode {
                    try? OfflineManager.shared.overrideDefaultPlaybackSpeed(playbackRate, for: episode.podcastId, episodeID: episode.id)
                } else {
                    try? OfflineManager.shared.overrideDefaultPlaybackSpeed(playbackRate, for: item.id, episodeID: nil)
                }
            }
            
            if playing {
                audioPlayer.rate = playbackRate
            }
        }
    }
    
    // MARK: Utility
    
    internal var nowPlayingInfo: [String: Any]
    
    internal var tracks: [PlayableItem.AudioTrack]
    internal var currentTrackIndex: Int?
    
    internal var lastPause: Date?
    internal var playbackReporter: PlaybackReporter?
    
    internal var systemVolume: Float
    internal var volumeSubscription: AnyCancellable?
    
    internal var enableChapterTrack: Bool
    internal var skipForwardsInterval: Int
    internal var skipBackwardsInterval: Int
    
    internal let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "AudioPlayer")
    
    private init() {
        audioPlayer = AVQueuePlayer()
        
        buffering = false
        
        item = nil
        queue = []
        
        chapters = []
        currentChapterIndex = nil
        
        playbackRate = 0
        
        nowPlayingInfo = [:]
        
        tracks = []
        currentTrackIndex = nil
        
        lastPause = nil
        playbackReporter = nil
        
        systemVolume = 0.5
        
        enableChapterTrack = Defaults[.enableChapterTrack]
        skipForwardsInterval = Defaults[.skipForwardsInterval]
        skipBackwardsInterval = Defaults[.skipBackwardsInterval]
        
        updateAudioSession(active: false)
    }
}

public extension AudioPlayer {
    var remaining: Double {
        (chapterDuration - chapterCurrentTime) * (1 / Double(playbackRate))
    }
    
    var chapter: PlayableItem.Chapter? {
        if let currentChapterIndex {
            return chapters[currentChapterIndex]
        }
        
        return nil
    }
}

public extension AudioPlayer {
    static let shared = AudioPlayer()
}
