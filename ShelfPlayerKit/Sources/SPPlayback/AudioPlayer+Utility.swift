//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.02.24.
//

import Foundation
import Intents
import AVKit
import SPFoundation
import SPNetwork
import SPExtension

#if canImport(SPOfflineExtended)
import SPOffline
import SPOfflineExtended
#endif

public extension AudioPlayer {
    var chapter: PlayableItem.Chapter? {
        if let currentChapterIndex {
            return chapters[currentChapterIndex]
        }
        
        return nil
    }
}

internal extension AudioPlayer {
    func queue(currentTime: TimeInterval) -> [PlayableItem.AudioTrack] {
        tracks.filter { $0.offset > currentTime }
    }
    
    func history() -> [PlayableItem.AudioTrack] {
        guard let currentTrackIndex else {
            return []
        }
        
        return Array(tracks.prefix(currentTrackIndex))
    }
    
    func trackIndex(currentTime: TimeInterval) -> Int? {
        tracks.firstIndex { $0.offset <= currentTime && $0.offset + $0.duration > currentTime }
    }
}

internal extension AudioPlayer {
    func updateChapterIndex() {
        if !enableChapterTrack || chapters.count <= 1 {
            chapterTTL = .infinity
            currentChapterIndex = nil
            
            return
        }
        
        currentChapterIndex = chapters.firstIndex { $0.start <= itemCurrentTime && $0.end > itemCurrentTime }
        
        if let chapter {
            chapterTTL = chapter.end
        }
    }
}

internal extension AudioPlayer {
    func retrievePlaybackSession(offline: Bool = false) async throws -> TimeInterval {
        guard let item else {
            throw AudioPlayerError.missing
        }
        
        var tracks = [PlayableItem.AudioTrack]()
        var chapters = [PlayableItem.Chapter]()
        
        let startTime: TimeInterval
        
        // Try to start playback session
        do {
            let playbackSessionId: String
            playbackReporter = nil
            
            if offline {
                throw AudioPlayerError.offline
            }
            
            (tracks, chapters, startTime, playbackSessionId) = try await AudiobookshelfClient.shared.startPlaybackSession(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID)
            playbackReporter = PlaybackReporter(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID, playbackSessionId: playbackSessionId)
        } catch {
            playbackReporter = PlaybackReporter(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID, playbackSessionId: nil)
            
            let entity = OfflineManager.shared.progressEntity(item: item)
            
            if entity.isFinished {
                startTime = 0
            } else {
                var currentTime = entity.currentTime
                
                if entity.lastUpdate.timeIntervalSince(Date()) >= 10 * 60 {
                    currentTime -= 30
                }
                
                startTime = max(currentTime, 0)
            }
        }
        
        #if canImport(SPOfflineExtended)
        if OfflineManager.shared.offlineStatus(parentId: item.id) == .downloaded {
            // Overwrite remote URLs
            tracks = try OfflineManager.shared.audioTracks(parentId: item.id)
            chapters = try OfflineManager.shared.chapters(itemId: item.id)
        }
        #endif
        
        guard !tracks.isEmpty else {
            // Could not receive playback session and item is not downloaded
            
            playbackReporter = nil
            throw AudioPlayerError.missing
        }
        
        self.tracks = tracks
        self.chapters = chapters
        
        return startTime
    }
    
    func avPlayerItem(item: PlayableItem, track: PlayableItem.AudioTrack) -> AVPlayerItem {
        #if canImport(SPOfflineExtended)
        if let trackURL = try? OfflineManager.shared.url(for: track, itemId: item.id) {
            return AVPlayerItem(url: trackURL)
        }
        #endif
        
        let url = AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ])
        
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": AudiobookshelfClient.shared.customHTTPHeaderDictionary,
        ])
        
        return AVPlayerItem(asset: asset)
    }
}

internal extension AudioPlayer {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
        } catch {
            logger.fault("Failed to setup audio session")
        }
    }
    
    func updateAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
            try AVAudioSession.sharedInstance().setSupportsMultichannelContent(true)
        } catch {
            logger.fault("Failed to update audio session")
        }
    }
}
