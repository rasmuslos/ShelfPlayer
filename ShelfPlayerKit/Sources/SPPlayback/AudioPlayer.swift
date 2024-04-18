//
//  AudioPlayer.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import Defaults
import SPBase
import AVKit
import OSLog

@Observable
public class AudioPlayer {
    // MARK: Public
    public internal(set) var item: PlayableItem?
    public internal(set) var chapters: PlayableItem.Chapters
    
    public internal(set) var pauseAtEndOfChapter = false
    public internal(set) var remainingSleepTimerTime: Double?
    
    // MARK: Observable variables updated by the time observer
    public internal(set) var duration: Double = .infinity
    public internal(set) var currentTime: Double = .infinity
    
    public internal(set) var chapter: PlayableItem.Chapter?
    public internal(set) var buffering = true {
        didSet {
            updateChapterIndex()
        }
    }
    
    public var _playing = false
    public var playing: Bool {
        get {
            _playing
        }
        set {
            setPlaying(newValue)
        }
    }
    
    public var _playbackRate: Float = 1.0
    public var playbackRate: Float {
        get {
            _playbackRate
        }
        set {
            setPlaybackRate(newValue)
        }
    }
    
    // MARK: Internal
    
    internal var audioPlayer: AVQueuePlayer
    internal var nowPlayingInfo: [String: Any]
    
    internal var cache: [String: Double]
    internal var tracks: PlayableItem.AudioTracks
    
    internal var lastPause: Date?
    internal var playbackReporter: PlaybackReporter?
    
    internal var activeAudioTrackIndex: Int?
    internal var activeChapterIndex: Int? {
        didSet {
            updateNowPlayingTitle()
        }
    }
    
    internal var enableChapterTrack = Defaults[.enableChapterTrack]
    internal var skipBackwardsInterval = Defaults[.skipBackwardsInterval]
    internal var skipForwardsInterval = Defaults[.skipForwardsInterval]
    
    internal let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "AudioPlayer")
    
    // MARK: Initilaizer
    private init() {
        self.tracks = []
        self.chapters = []
        
        activeAudioTrackIndex = nil
        
        audioPlayer = AVQueuePlayer()
        
        nowPlayingInfo = [:]
        cache = [:]
        
        setupObservers()
        setupTimeObserver()
        setupRemoteControls()
        
        updateAudioSession(active: false)
    }
}

// MARK: Connivence

public extension AudioPlayer {
    var adjustedTimeLeft: Double {
        (duration - currentTime) * (1 / Double(playbackRate))
    }
}

// MARK: Singleton

extension AudioPlayer {
    public static let shared = AudioPlayer()
}
