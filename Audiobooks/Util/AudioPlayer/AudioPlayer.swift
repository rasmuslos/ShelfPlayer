//
//  AudioPlayer.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import AVKit
import MediaPlayer
import OSLog

class AudioPlayer {
    private(set) var item: PlayableItem?
    private var tracks: PlayableItem.AudioTracks
    private(set) var chapters: PlayableItem.Chapters
    
    private var activeAudioTrackIndex: Int?
    private var activeChapterIndex: Int?
    
    private var audioPlayer: AVQueuePlayer
    private(set) var buffering: Bool = false
    private var nowPlayingInfo: [String: Any]
    
    private var playbackReporter: PlaybackReporter?
    
    private var cache: [String: Double]
    
    private var enableChapterTrack: Bool
    private var skipBackwardsInterval: Int!
    private var skipForwardsInterval: Int!
    
    let logger = Logger(subsystem: "io.rfk.audiobooks", category: "AudioPlayer")
    
    private init() {
        self.tracks = []
        self.chapters = []
        
        activeAudioTrackIndex = nil
        
        audioPlayer = AVQueuePlayer()
        buffering = false
        
        nowPlayingInfo = [:]
        cache = [:]
        
        enableChapterTrack = UserDefaults.standard.bool(forKey: "enableChapterTrack")
        fetchSkipIntervals()
        
        setupObservers()
        setupTimeObserver()
        setupRemoteControls()
        
        setupAudioSession()
        updateAudioSession(active: false)
    }
}

// MARK: Methods

extension AudioPlayer {
    func startPlayback(item: PlayableItem, tracks: PlayableItem.AudioTracks, chapters: PlayableItem.Chapters, startTime: Double, playbackReporter: PlaybackReporter) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        self.item = item
        self.tracks = tracks.sorted()
        self.chapters = chapters.sorted()
        
        seek(to: startTime)
        setPlaying(true)
        
        updateAudioSession(active: true)
        updateChapterIndex()
        setupNowPlayingMetadata()
        
        self.playbackReporter = playbackReporter
        
        Task { @MainActor in
            NotificationCenter.default.post(name: Self.startStopNotification, object: nil)
        }
    }
    
    func stopPlayback() {
        item = nil
        tracks = []
        chapters = []
        
        playbackReporter = nil
        
        activeAudioTrackIndex = nil
        activeChapterIndex = nil
        
        audioPlayer.removeAllItems()
        
        updateAudioSession(active: false)
        clearNowPlayingMetadata()
        
        Task { @MainActor in
            NotificationCenter.default.post(name: Self.startStopNotification, object: nil)
        }
    }
    
    func setPlaying(_ playing: Bool) {
        updateNowPlayingStatus()
        
        if playing {
            audioPlayer.play()
        } else {
            audioPlayer.pause()
        }
        
        playbackReporter?.reportProgress(playing: playing, currentTime: getCurrentTime(), duration: getDuration())
        Task { @MainActor in
            NotificationCenter.default.post(name: Self.playPauseNotification, object: nil)
        }
    }
    
    func seek(to: Double, includeChapterOffset: Bool = false) {
        if to < 0 {
            seek(to: 0, includeChapterOffset: includeChapterOffset)
            return
        }
        
        var to = to
        if includeChapterOffset {
            to += AudioPlayer.shared.getChapter()?.start ?? 0
        }
        
         if let index = getTrackIndex(currentTime: to) {
            if index == activeAudioTrackIndex {
                let offset = getTrack(currentTime: to)!.offset
                audioPlayer.seek(to: CMTime(seconds: to - offset, preferredTimescale: 1000))
            } else {
                let resume = isPlaying()
                
                let track = getTrack(currentTime: to)!
                let queue = getQueue(currentTime: to)
                
                audioPlayer.pause()
                audioPlayer.removeAllItems()
                
                audioPlayer.insert(getAVPlayerItem(track: track), after: nil)
                for queueTrack in queue {
                    audioPlayer.insert(getAVPlayerItem(track: queueTrack), after: nil)
                }
                
                audioPlayer.seek(to: CMTime(seconds: to - track.offset, preferredTimescale: 1000))
                
                activeAudioTrackIndex = index
                setPlaying(resume)
            }
         } else if to >= getDuration() {
             playbackReporter?.reportProgress(currentTime: getDuration(), duration: getDuration())
             stopPlayback()
         } else {
            logger.fault("Seek to position outside of range")
        }
        
        updateChapterIndex()
        updateNowPlayingStatus()
    }
    
    func setPlaybackRate(_ playbackRate: Float) {
        audioPlayer.defaultRate = playbackRate
        
        if isPlaying() {
            audioPlayer.rate = playbackRate
        }
        
        NotificationCenter.default.post(name: Self.playbackRateChanged, object: nil)
    }
}

// MARK: Getter

extension AudioPlayer {
    func isPlaying() -> Bool {
        audioPlayer.rate > 0
    }
    
    func getPlaybackRate() -> Float {
        audioPlayer.defaultRate
    }
    
    func getCurrentTime() -> Double {
        var seconds: Double
        
        if tracks.count == 0 {
            seconds = audioPlayer.currentTime().seconds
        } else {
            let cacheKey = "currentTimeOffset.\(item?.id ?? "unknown").\(activeAudioTrackIndex ?? -1)"
            
            if let cached = cache[cacheKey] {
                seconds = cached
            } else {
                let history = getHistory()
                let offset = history.reduce(0, { $0 + $1.duration })
                
                cache[cacheKey] = offset
                seconds = offset
            }
            
            seconds += audioPlayer.currentTime().seconds
        }
        
        return seconds.isFinite ? seconds : 0
    }
    func getDuration() -> Double {
        let seconds: Double
        
        if tracks.count == 1 {
            seconds = audioPlayer.currentItem?.duration.seconds ?? 0
        } else {
            let cacheKey = "duration.\(item?.id ?? "unknown").\(activeAudioTrackIndex ?? -1)"
            
            if let cached = cache[cacheKey] {
                seconds = cached
            } else {
                seconds = tracks.reduce(0, { $0 + $1.duration })
                cache[cacheKey] = seconds
            }
        }
        
        return seconds.isFinite ? seconds : 0
    }
}

// MARK: Queue

extension AudioPlayer {
    private func getQueue(currentTime: Double) -> PlayableItem.AudioTracks {
        tracks.filter { $0.offset > currentTime }
    }
    private func getHistory(currentTime: Double) -> PlayableItem.AudioTracks {
        tracks.filter { $0.offset + $0.duration < currentTime }
    }
    
    private func getHistory() -> PlayableItem.AudioTracks {
        if let activeAudioTrackIndex = activeAudioTrackIndex {
            return Array(tracks.prefix(activeAudioTrackIndex))
        } else {
            return []
        }
    }
    
    private func getTrack(currentTime: Double) -> PlayableItem.AudioTrack? {
        tracks.first { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
    private func getTrackIndex(currentTime: Double) -> Int? {
        tracks.firstIndex { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
}

// MARK: Chapters

extension AudioPlayer {
    private func updateChapterIndex() {
        if !enableChapterTrack || chapters.count <= 1 {
            activeChapterIndex = nil
            return
        }
        
        let currentTime = getCurrentTime()
        let chapter = chapters.firstIndex { $0.start <= currentTime && $0.end > currentTime }
        
        activeChapterIndex = chapter
    }
    func getChapter() -> PlayableItem.Chapter? {
        if let activeChapterIndex = activeChapterIndex {
            return chapters[activeChapterIndex]
        } else {
            return nil
        }
    }
    
    func getChapterDuration() -> Double {
        if let chapter = getChapter() {
            return chapter.end - chapter.start
        } else {
            return getDuration()
        }
    }
    func getChapterCurrentTime() -> Double {
        let currentTime = getCurrentTime()
        
        if let chapter = getChapter() {
            return currentTime - chapter.start
        } else {
            return currentTime
        }
    }
}

// MARK: Observers

extension AudioPlayer {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            playbackReporter?.reportProgress(currentTime: getCurrentTime(), duration: getDuration())
            
            let currentTime = getCurrentTime()
            if currentTime.isFinite && !currentTime.isNaN, Int(currentTime) % 5 == 0 {
                updateChapterIndex()
            }
            
            Task { @MainActor in
                NotificationCenter.default.post(name: Self.currentTimeChangedNotification, object: nil)
            }
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [weak self] _ in
            if self?.activeAudioTrackIndex == (self?.tracks.count ?? 0) - 1 {
                if let duration = self?.getDuration() {
                    self?.playbackReporter?.reportProgress(currentTime: duration, duration: duration)
                }
                
                self?.stopPlayback()
                return
            }
            
            self?.activeAudioTrackIndex? += 1
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(), queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                self?.setPlaying(false)
            case .ended:
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    self?.setPlaying(true)
                }
            default: ()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.playbackReporter = nil
        }
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.enableChapterTrack = UserDefaults.standard.bool(forKey: "enableChapterTrack")
            self?.fetchSkipIntervals()
        }
    }
}

// MARK: Remote controls

extension AudioPlayer {
    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            setPlaying(true)
            return .success
        }
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            setPlaying(false)
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            setPlaying(!isPlaying())
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackPositionCommandEvent {
                seek(to: changePlaybackPositionCommandEvent.positionTime, includeChapterOffset: true)
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        commandCenter.changePlaybackRateCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPChangePlaybackRateCommandEvent {
                setPlaybackRate(changePlaybackPositionCommandEvent.playbackRate)
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipBackwardsInterval)]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getCurrentTime() - changePlaybackPositionCommandEvent.interval)
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: skipForwardsInterval)]
        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getCurrentTime() + changePlaybackPositionCommandEvent.interval)
                return .success
            }
            
            return .commandFailed
        }
    }
}

// MARK: Audio session

extension AudioPlayer {
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    
    private func updateAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            logger.fault("Failed to update audio session")
        }
    }
}

// MARK: Now playing metadata

extension AudioPlayer {
    private func setupNowPlayingMetadata() {
        if let item = item {
            Task.detached { [self] in
                nowPlayingInfo = [:]
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = item.name
                nowPlayingInfo[MPMediaItemPropertyArtist] = item.author
                nowPlayingInfo[MPNowPlayingInfoPropertyChapterCount] = chapters.count
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                
                if let imageUrl = item.image?.url, let data = try? Data(contentsOf: imageUrl), let image = UIImage(data: data) {
                    setNowPlayingArtwork(image: image)
                }
            }
        }
    }
    private func setNowPlayingArtwork(image: UIImage) {
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { _ -> UIImage in image })
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingStatus() {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = getPlaybackRate()
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = getChapterDuration()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = getChapterCurrentTime()
        nowPlayingInfo[MPNowPlayingInfoPropertyChapterNumber] = activeChapterIndex
        
        MPNowPlayingInfoCenter.default().playbackState = isPlaying() ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func clearNowPlayingMetadata() {
        nowPlayingInfo = [:]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: Helper

extension AudioPlayer {
    private func getAVPlayerItem(track: PlayableItem.AudioTrack) -> AVPlayerItem {
        if item?.offline == .downloaded {
            return AVPlayerItem(url: URL(string: track.contentUrl)!)
        } else {
            return AVPlayerItem(url: AudiobookshelfClient.shared.serverUrl
                .appending(path: track.contentUrl.removingPercentEncoding ?? "")
                .appending(queryItems: [
                    URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
                ]))
        }
    }
    
    private func fetchSkipIntervals() {
        skipBackwardsInterval = UserDefaults.standard.integer(forKey: "skipBackwardsInterval")
        if skipBackwardsInterval == 0 {
            skipBackwardsInterval = 30
            UserDefaults.standard.set(30, forKey: "skipBackwardsInterval")
        }
        
        skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
        if skipForwardsInterval == 0 {
            skipForwardsInterval = 30
            UserDefaults.standard.set(30, forKey: "skipForwardsInterval")
        }
    }
}

// MARK: Singleton

extension AudioPlayer {
    static let shared = AudioPlayer()
}
