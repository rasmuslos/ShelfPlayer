//
//  LocalAudioEndpoint.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
import Combine
@preconcurrency import AVKit
import MediaPlayer
import OSLog
import Defaults
import SPFoundation
import SPPersistence

final class LocalAudioEndpoint: AudioEndpoint {
    let id = UUID()
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "LocalAudioEndpoint")
    
    let audioPlayer: AVQueuePlayer
    
    nonisolated(unsafe) var playbackReporter: PlaybackReporter!
    
    nonisolated(unsafe) var currentItemID: ItemIdentifier
    nonisolated(unsafe) var queue: ActorArray<QueueItem>
    
    nonisolated(unsafe) var audioTracks: [PlayableItem.AudioTrack]
    nonisolated(unsafe) var activeAudioTrackIndex: Int
    
    nonisolated(unsafe) var chapters: [Chapter]
    nonisolated(unsafe) var activeChapterIndex: Int?
    
    nonisolated(unsafe) var isPlaying: Bool
    
    nonisolated(unsafe) var isBuffering: Bool
    nonisolated(unsafe) var activeOperationCount: Int {
        didSet {
            Task {
                await AudioPlayer.shared.isBusyDidChange()
            }
        }
    }
    
    nonisolated(unsafe) var systemVolume: Percentage
    
    nonisolated(unsafe) var duration: TimeInterval?
    nonisolated(unsafe) var currentTime: TimeInterval?
    
    nonisolated(unsafe) var chapterDuration: TimeInterval?
    nonisolated(unsafe) var chapterCurrentTime: TimeInterval?
    
    nonisolated(unsafe) private var chapterValidUntil: TimeInterval
    nonisolated(unsafe) private var volumeSubscription: AnyCancellable?
    
    init(itemID: ItemIdentifier, withoutListeningSession: Bool) async throws {
        logger.info("Starting up local audio endpoint with item ID \(itemID) (without listening session: \(withoutListeningSession))")
        
        playbackReporter = nil
        audioPlayer = .init()
        
        currentItemID = itemID
        
        queue = .init()
        
        audioTracks = []
        activeAudioTrackIndex = -1
        
        chapters = []
        activeChapterIndex = nil
        
        isPlaying = false
        
        isBuffering = true
        activeOperationCount = 0
        
        systemVolume = 0
        
        duration = nil
        currentTime = nil
        
        chapterDuration = nil
        chapterCurrentTime = nil
        
        chapterValidUntil = -1
        
        setupObservers()
        
        try await start(withoutListeningSession: withoutListeningSession)
    }
    
    var isBusy: Bool {
        isBuffering || activeOperationCount > 0
    }
    var volume: Percentage {
        get {
            systemVolume
        }
        set {
            Task {
                await MPVolumeView.setVolume(Float(newValue))
            }
        }
    }
    var playbackRate: Percentage {
        get {
            .init(audioPlayer.defaultRate)
        }
        set {
            audioPlayer.defaultRate = Float(newValue)
            
            if audioPlayer.rate > 0 {
                audioPlayer.rate = audioPlayer.defaultRate
            }
            
            Task {
                await AudioPlayer.shared.playbackRateDidChange(endpointID: id, playbackRate: newValue)
            }
        }
    }
}

extension LocalAudioEndpoint {
    func queue(_ items: [QueueItem]) async throws {
        
    }
    
    func stop() async {
        await playbackReporter.finalize()
        audioPlayer.removeAllItems()
        
        await AudioPlayer.shared.didStopPlaying(endpointID: id)
    }
    
    func play() async {
        audioPlayer.play()
        isPlaying = true
        
        await playbackReporter.didChangePlayState(isPlaying: true)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: true)
    }
    
    func pause() async {
        audioPlayer.pause()
        isPlaying = false
        
        await playbackReporter.didChangePlayState(isPlaying: false)
        await AudioPlayer.shared.playStateDidChange(endpointID: id, isPlaying: false)
    }
    
    func seek(to time: TimeInterval, insideChapter: Bool) async throws {
        logger.info("Seeking to \(time)")
        
        guard time >= 0 else {
            try await seek(to: 0, insideChapter: insideChapter)
            return
        }
        
        if let duration, time >= duration {
            await playbackReporter.update(currentTime: duration)
            await playbackReporter.finalize()
            
            await AudioPlayer.shared.stop(endpointID: id)
            return
        }
        
        activeOperationCount += 1
        audioPlayer.pause()
        
        let index = try! audioTrackIndex(at: time)
        
        if index != activeAudioTrackIndex {
            let playerItems = audioPlayer.items()
            
            if playerItems.count > index && index > activeAudioTrackIndex {
                for surplusIndex in 1..<(index - activeAudioTrackIndex) {
                    audioPlayer.remove(playerItems[surplusIndex])
                }
                
                audioPlayer.advanceToNextItem()
            } else {
                audioPlayer.removeAllItems()
                
                let headers = Dictionary(uniqueKeysWithValues: try await ABSClient[currentItemID.connectionID].headers.map { ($0.key, $0.value) })
                
                for audioTrack in audioTracks[index..<audioTracks.endIndex] {
                    let asset = AVURLAsset(url: audioTrack.resource, options: [
                        "AVURLAssetHTTPHeaderFieldsKey": headers,
                    ])
                    let playerItem = AVPlayerItem(asset: asset)
                    
                    audioPlayer.insert(playerItem, after: nil)
                }
            }
            
            activeAudioTrackIndex = index
        }
        
        await audioPlayer.seek(to: CMTime(seconds: time - audioTracks[index].offset, preferredTimescale: 1000))
        
        updateChapterIndex()
        currentTime = time
        
        if isPlaying {
            audioPlayer.play()
        }
        
        activeOperationCount -= 1
    }
}

private extension LocalAudioEndpoint {
    func start(withoutListeningSession: Bool) async throws {
        let downloadStatus = await PersistenceManager.shared.download.status(of: currentItemID)
        
        guard downloadStatus != .downloading else {
            throw AudioPlayerError.downloading
        }
        
        audioTracks = []
        activeAudioTrackIndex = -1
        
        chapters = []
        activeChapterIndex = nil
        
        isPlaying = false
        
        activeOperationCount += 1
        isBuffering = true
        
        duration = nil
        currentTime = nil
        
        chapterDuration = nil
        chapterCurrentTime = nil
        
        var audioTracks = [PlayableItem.AudioTrack]()
        var chapters = [Chapter]()
        
        let startTime: TimeInterval
        let sessionID: String?
        
        do {
            if withoutListeningSession {
                throw AudioPlayerError.offline
            }
            
            // Attempt to start a playback session
            
            (audioTracks, chapters, startTime, sessionID) = try await ABSClient[currentItemID.connectionID].startPlaybackSession(itemID: currentItemID)
        } catch {
            // Fall back to resolving and reporting locally
            
            let entity = await PersistenceManager.shared.progress[currentItemID]
            
            if entity.isFinished {
                startTime = 0
            } else {
                var currentTime = entity.currentTime
                
                if Defaults[.enableSmartRewind] && entity.lastUpdate.timeIntervalSince(Date()) >= 10 * 60 {
                    currentTime -= 30
                }
                
                startTime = max(currentTime, 0)
            }
            
            sessionID = nil
        }
        
        do {
            if downloadStatus == .completed {
                audioTracks = try await PersistenceManager.shared.download.audioTracks(for: currentItemID)
                chapters = await PersistenceManager.shared.download.chapters(itemID: currentItemID)
            }
            
            guard !audioTracks.isEmpty else {
                throw AudioPlayerError.loadFailed
            }
        } catch {
            activeOperationCount -= 1
            logger.error("Failed to load audio tracks: \(error)")
            
            throw error
        }
        
        self.audioTracks = audioTracks.sorted()
        self.chapters = chapters.sorted()
        
        playbackReporter = .init(itemID: currentItemID, sessionID: sessionID)
        
        do {
            try await seek(to: startTime, insideChapter: false)
        } catch {
            logger.error("Failed to seek to start time: \(error)")
        }
        
        await AudioPlayer.shared.didStartPlaying(endpointID: id, itemID: currentItemID, at: startTime)
        
        await updateDuration()
        
        // TODO: override
        playbackRate = Defaults[.defaultPlaybackRate]
        
        await play()
        
        activeOperationCount -= 1
    }
    
    func updateChapterIndex() {
        if let currentTime {
            activeChapterIndex = chapterIndex(at: currentTime)
        } else if !Defaults[.enableChapterTrack] {
            activeChapterIndex = nil
        }
    }
    
    func audioTrackIndex(at time: TimeInterval) throws -> Int {
        if let index = audioTracks.firstIndex(where: { time >= $0.offset && time < ($0.offset + $0.duration) }) {
            index
        } else {
            throw AudioPlayerError.missingAudioTrack
        }
    }
    func chapterIndex(at time: TimeInterval) -> Int? {
        guard Defaults[.enableChapterTrack] else {
            return nil
        }
        
        return chapters.firstIndex(where: { time >= $0.startOffset && time < $0.endOffset })
    }
    
    func updateDuration() async {
        if let last = audioTracks.last {
            duration = last.offset + last.duration
        }
        
        if let activeChapterIndex {
            chapterDuration = chapters[activeChapterIndex].endOffset - chapters[activeChapterIndex].startOffset
        } else {
            chapterDuration = duration
        }
        
        if let duration {
            await playbackReporter.update(duration: duration)
        }
        
        await AudioPlayer.shared.durationsDidChange(endpointID: id, itemDuration: duration, chapterDuration: chapterDuration)
    }
    
    func setupObservers() {
        volumeSubscription = AVAudioSession.sharedInstance().publisher(for: \.outputVolume).sink { [weak self] volume in
            self?.systemVolume = .init(volume)
            
            guard let id = self?.id, let systemVolume = self?.systemVolume else {
                return
            }
            
            Task {
                await AudioPlayer.shared.volumeDidChange(endpointID: id, volume: systemVolume)
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self else {
                return
            }
            
            print(audioTracks.endIndex)
            
            if activeAudioTrackIndex == audioTracks.endIndex - 1 {
                // TODO: queue
                
                Task {
                    await AudioPlayer.shared.stop(endpointID: id)
                }
            } else {
                activeAudioTrackIndex += 1
            }
        }
        
        audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: nil) { [weak self] _ in
            Task {
                // MARK: Buffering
                
                let isBuffering: Bool
                
                if let item = self?.audioPlayer.currentItem {
                    isBuffering = !(item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp)
                } else {
                    isBuffering = true
                }
                
                if self?.isBuffering != isBuffering {
                    self?.isBuffering = isBuffering
                    
                    if let id = self?.id {
                        await AudioPlayer.shared.bufferHealthDidChange(endpointID: id, isBuffering: isBuffering)
                    }
                }
                
                // MARK: Current time
                
                if let activeAudioTrackIndex = self?.activeAudioTrackIndex, activeAudioTrackIndex >= 0, let audioTrack = self?.audioTracks[activeAudioTrackIndex], let seconds = self?.audioPlayer.currentTime().seconds {
                    self?.currentTime = audioTrack.offset + seconds
                }
                
                // MARK: Chapter
                
                if let chapters = self?.chapters, !chapters.isEmpty, let currentTime = self?.chapterCurrentTime, let chapterValidUntil = self?.chapterValidUntil, chapterValidUntil < currentTime {
                    self?.activeChapterIndex = self?.chapterIndex(at: currentTime)
                    
                    if let activeChapterIndex = self?.activeChapterIndex {
                        self?.chapterValidUntil = self?.chapters[activeChapterIndex].endOffset ?? -1
                    }
                    
                    if let id = self?.id {
                        await AudioPlayer.shared.chapterDidChange(endpointID: id, currentChapterIndex: self?.activeChapterIndex)
                    }
                    
                    await self?.updateDuration()
                }
                
                // MARK: Chapter current time
                
                if let currentTime = self?.currentTime, let activeChapterIndex = self?.activeChapterIndex, let chapter = self?.chapters[activeChapterIndex] {
                    self?.chapterCurrentTime = currentTime - chapter.startOffset
                } else {
                    self?.chapterCurrentTime = self?.currentTime
                }
                
                if let currentTime = self?.currentTime {
                    await self?.playbackReporter.update(currentTime: currentTime)
                }
                
                if let id = self?.id {
                    await AudioPlayer.shared.currentTimesDidChange(endpointID: id, itemCurrentTime: self?.currentTime, chapterCurrentTime: self?.chapterCurrentTime)
                }
            }
        }
    }
}
