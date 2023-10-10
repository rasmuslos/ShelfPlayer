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
    fileprivate var item: PlayableItem?
    fileprivate var tracks: PlayableItem.AudioTracks
    fileprivate var chapters: PlayableItem.Chapters
    
    fileprivate var activeAudioTrackIndex: Int
    
    fileprivate var audioPlayer: AVQueuePlayer
    fileprivate var buffering: Bool = false
    fileprivate var nowPlayingInfo: [String: Any]
    
    let logger = Logger(subsystem: "io.rfk.audiobooks", category: "AudioPlayer")
    
    private init() {
        self.tracks = []
        self.chapters = []
        
        activeAudioTrackIndex = -1
        
        audioPlayer = AVQueuePlayer()
        buffering = false
        nowPlayingInfo = [:]
        
        setupObservers()
        setupTimeObserver()
        setupRemoteControls()
        
        setupAudioSession()
        updateAudioSession(active: false)
    }
}

// MARK: Methods

extension AudioPlayer {
    func startPlayback(item: PlayableItem, tracks: PlayableItem.AudioTracks, chapters: PlayableItem.Chapters, startTime: Double) {
        if tracks.isEmpty {
            return
        }
        
        stopPlayback()
        
        self.item = item
        self.tracks = tracks
        self.chapters = chapters
        
        seek(to: startTime)
        setPlaying(true)
        
        updateAudioSession(active: true)
        setupNowPlayingMetadata()
    }
    
    func stopPlayback() {
        item = nil
        tracks = []
        chapters = []
        
        activeAudioTrackIndex = -1
        audioPlayer.removeAllItems()
        
        updateAudioSession(active: false)
        clearNowPlayingMetadata()
    }
    
    func setPlaying(_ playing: Bool) {
        updateNowPlayingStatus()
        
        if playing {
            audioPlayer.play()
        } else {
            audioPlayer.pause()
        }
    }
    
    func seek(to: Double) {
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
        } else {
            logger.fault("Seek to position outside range")
        }
    }
    
    func setPlaybackRate(_ playbackRate: Float) {
        audioPlayer.defaultRate = playbackRate
        
        if isPlaying() {
            audioPlayer.rate = playbackRate
        }
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
        if tracks.count == 0 {
            return audioPlayer.currentTime().seconds
        } else {
            let history = getHistory()
            return history.reduce(0, { $0 + $1.duration }) + audioPlayer.currentTime().seconds
        }
    }
    func getDuration() -> Double {
        if tracks.count == 1 {
            return audioPlayer.currentItem?.duration.seconds ?? 0
        } else {
            return tracks.reduce(0, { $0 + $1.duration })
        }
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
        Array(tracks.prefix(activeAudioTrackIndex))
    }
    
    private func getTrack(currentTime: Double) -> PlayableItem.AudioTrack? {
        tracks.first { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
    private func getTrackIndex(currentTime: Double) -> Int? {
        tracks.firstIndex { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
}

// MARK: Observers

extension AudioPlayer {
    private func setupTimeObserver() {
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000), queue: nil) { [unowned self] _ in
            updateNowPlayingStatus()
            buffering = !(audioPlayer.currentItem?.isPlaybackLikelyToKeepUp ?? false)
            
            Task { @MainActor in
                // NotificationCenter.default.post(name: NSNotification.PositionUpdated, object: nil)
            }
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [weak self] _ in
            if self?.activeAudioTrackIndex == (self?.tracks.count ?? 0) - 1 {
                self?.stopPlayback()
            }
            
            self?.activeAudioTrackIndex += 1
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
                seek(to: changePlaybackPositionCommandEvent.positionTime)
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
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getCurrentTime() + changePlaybackPositionCommandEvent.interval)
                return .success
            }
            
            return .commandFailed
        }
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            if let changePlaybackPositionCommandEvent = event as? MPSkipIntervalCommandEvent {
                seek(to: getCurrentTime() - changePlaybackPositionCommandEvent.interval)
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
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = getDuration()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = getCurrentTime()
        
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
        return AVPlayerItem(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ]))
    }
}

// MARK: Singleton

extension AudioPlayer {
    static let shared = AudioPlayer()
}
