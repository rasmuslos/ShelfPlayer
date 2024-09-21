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
                SleepTimer.shared.didPlay(pausedFor: lastPause?.distance(to: .now) ?? 0)
                
                Task {
                    if Defaults[.smartRewind], let lastPause = lastPause, lastPause.timeIntervalSince(Date()) <= -10 * 60 {
                        await seek(to: itemCurrentTime - 30)
                    }
                    
                    lastPause = nil
                    audioPlayer.play()
                    updateAudioSession(active: true)
                }
            } else {
                lastPause = Date()
                audioPlayer.pause()
                
                SleepTimer.shared.didPause()
            }
            
            Task {
                await updateNowPlayingWidget()
            }
            playbackReporter?.reportProgress(currentTime: itemCurrentTime, duration: itemDuration, forceReport: true)
            
            NotificationCenter.default.post(name: AudioPlayer.playingDidChangeNotification, object: nil)
        }
    }
    public internal(set) var buffering: Bool {
        didSet {
            guard oldValue != buffering else {
                return
            }
            
            updateChapterIndex()
            NotificationCenter.default.post(name: AudioPlayer.bufferingDidChangeNotification, object: nil)
        }
    }
    
    public var itemCurrentTime: TimeInterval {
        get {
            var seconds: TimeInterval
            
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
    public var itemDuration: TimeInterval {
        let duration = tracks.reduce(0, { $0 + $1.duration })
        
        guard duration.isFinite && !duration.isNaN else {
            return 0
        }
        
        return duration
    }
    
    public var chapterCurrentTime: TimeInterval {
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
    public var chapterDuration: TimeInterval {
        if let chapter {
            return chapter.end - chapter.start
        } else {
            return itemDuration
        }
    }
    
    public var volume: Percentage {
        get {
            .init(systemVolume)
        }
        set {
            guard newValue != volume else {
                return
            }
            
            Task { @MainActor in
                MPVolumeView.setVolume(.init(newValue))
            }
            
            NotificationCenter.default.post(name: AudioPlayer.volumeDidChangeNotification, object: nil)
        }
    }
    
    public internal(set) var item: PlayableItem? {
        didSet {
            guard oldValue != item else {
                return
            }
            
            Task {
                await populateNowPlayingWidgetMetadata()
            }
            NotificationCenter.default.post(name: AudioPlayer.itemDidChangeNotification, object: nil)
        }
    }
    public internal(set) var queue: [PlayableItem] {
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
            
            Task {
                await updateNowPlayingTitle()
            }
            NotificationCenter.default.post(name: AudioPlayer.chapterDidChangeNotification, object: nil)
        }
    }
    public internal(set) var chapters: [PlayableItem.Chapter] {
        didSet {
            guard oldValue != chapters else {
                return
            }
            
            NotificationCenter.default.post(name: AudioPlayer.chaptersDidChangeNotification, object: nil)
        }
    }
    
    public var playbackRate: Percentage {
        didSet {
            guard oldValue != playbackRate else {
                return
            }
            
            audioPlayer.defaultRate = .init(playbackRate)
            
            if let item {
                try? OfflineManager.shared.overrideDefaultPlaybackSpeed(playbackRate, for: item.identifiers.itemID, episodeID: item.identifiers.episodeID)
            }
            
            if playing {
                audioPlayer.rate = .init(playbackRate)
            }
            
            NotificationCenter.default.post(name: AudioPlayer.speedDidChangeNotification, object: nil)
        }
    }
    
    // MARK: Utility
    
    internal var nowPlayingInfo: SyncDictionary<String, Any>
    
    internal var tracks: [PlayableItem.AudioTrack]
    internal var currentTrackIndex: Int?
    
    internal var chapterTTL: TimeInterval
    internal var lastWidgetUpdate: Date?
    
    internal var lastPause: Date?
    internal var playbackReporter: PlaybackReporter?
    
    internal var systemVolume: Float
    internal var volumeSubscription: AnyCancellable?
    
    internal var timeSubscription: Any?
    internal var rateSubscription: NSKeyValueObservation?
    
    internal var timeoutDispatchSource: DispatchSourceTimer?
    
    internal var enableChapterTrack: Bool {
        didSet {
            updateChapterIndex()
        }
    }
    internal var skipForwardsInterval: Int
    internal var skipBackwardsInterval: Int
    
    public var isUsingExternalRoute: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType != .builtInSpeaker
    }
    
    internal let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "AudioPlayer")
    internal let dispatchQueue = DispatchQueue(label: "io.rfk.shelfplayer.queue", attributes: .concurrent)
    
    private init() {
        audioPlayer = AVQueuePlayer()
        buffering = true
        
        item = nil
        queue = []
        
        chapters = []
        currentChapterIndex = nil
        
        playbackRate = 0
        
        nowPlayingInfo = .init([:])
        
        tracks = []
        currentTrackIndex = nil
        
        chapterTTL = .infinity
        
        lastPause = nil
        playbackReporter = nil
        
        systemVolume = 0.5
        
        enableChapterTrack = Defaults[.enableChapterTrack]
        skipForwardsInterval = Defaults[.skipForwardsInterval]
        skipBackwardsInterval = Defaults[.skipBackwardsInterval]
        
        setupObservers()
        setupRemoteControls()
        
        setupAudioSession()
        updateAudioSession(active: false)
    }
}

internal extension AudioPlayer {
    enum AudioPlayerError: Error {
        case missing
    }
}

public extension AudioPlayer {
    static let shared = AudioPlayer()
}
