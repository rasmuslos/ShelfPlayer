//
//  LocalAudioEndpoint.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 20.02.25.
//

import Foundation
@preconcurrency import AVKit
import Defaults
import OSLog
import SPFoundation
import SPPersistence

final class LocalAudioEndpoint: AudioEndpoint {
    let id = UUID()
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "LocalAudioEndpoint")
    
    let audioPlayer: AVQueuePlayer
    
    nonisolated(unsafe) var currentItemID: ItemIdentifier
    nonisolated(unsafe) var queue: ActorArray<QueueItem>
    
    nonisolated(unsafe) var audioTracks: [PlayableItem.AudioTrack]
    nonisolated(unsafe) var activeAudioTrackIndex: Int
    
    nonisolated(unsafe) var chapters: [Chapter]
    nonisolated(unsafe) var activeChapterIndex: Int?
    
    nonisolated(unsafe) var isPlaying: Bool
    
    nonisolated(unsafe) var isBuffering: Bool
    nonisolated(unsafe) var activeOperationCount: Int
    
    nonisolated(unsafe) var systemVolume: Percentage
    
    nonisolated(unsafe) var duration: TimeInterval?
    nonisolated(unsafe) var currentTime: TimeInterval?
    
    nonisolated(unsafe) var chapterDuration: TimeInterval?
    nonisolated(unsafe) var chapterCurrentTime: TimeInterval?
    
    init(itemID: ItemIdentifier, withoutListeningSession: Bool) async throws {
        logger.info("Starting up local audio endpoint with item ID \(itemID) (without listening session: \(withoutListeningSession))")
        
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
        
        try await start(withoutListeningSession: withoutListeningSession)
    }
    
    var isBusy: Bool {
        isBuffering || activeOperationCount > 0
    }
    var volume: Percentage {
        systemVolume
    }
}

extension LocalAudioEndpoint {
    func queue(_ items: [QueueItem]) async throws {
        
    }
    
    func stop() {
        
    }
    
    func play() {
        
    }
    
    func pause() {
        
    }
    
    func seek(to time: TimeInterval) async {
        logger.info("Seeking to \(time)")
        
        guard time >= 0 else {
            await seek(to: 0)
            return
        }
        
        if let duration, time >= duration {
            // TODO: Played until end
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
                
                let headers = Dictionary(uniqueKeysWithValues: try! await ABSClient[currentItemID.connectionID].headers.map { ($0.key, $0.value) })
                
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
        
        self.audioTracks = audioTracks
        self.chapters = chapters
        
        await seek(to: startTime)
        
        activeOperationCount -= 1
        
        // TODO: Init reporter
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
}
