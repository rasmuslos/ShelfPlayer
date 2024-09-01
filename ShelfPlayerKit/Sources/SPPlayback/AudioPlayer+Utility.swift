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
    var remaining: TimeInterval {
        (chapterDuration - chapterCurrentTime) * (1 / .init(playbackRate))
    }
    var played: Percentage {
        .init((AudioPlayer.shared.chapterCurrentTime / AudioPlayer.shared.chapterCurrentTime) * 100)
    }
    
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
            chapterTTL = chapter.start + chapter.end
        }
    }
}

internal extension AudioPlayer {
    func retrievePlaybackSession() async throws -> TimeInterval {
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
            
            (tracks, chapters, startTime, playbackSessionId) = try await AudiobookshelfClient.shared.startPlaybackSession(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID)
            playbackReporter = PlaybackReporter(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID, playbackSessionId: playbackSessionId)
        } catch {
            playbackReporter = PlaybackReporter(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID, playbackSessionId: nil)
            
            let entity = OfflineManager.shared.progressEntity(item: item)
            
            if entity.progress >= 1 {
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
    
    func donateIntent() async throws {
        guard let item else {
            return
        }
        
        let intent = INPlayMediaIntent(
            mediaItems: MediaResolver.shared.convert(items: [item]),
            mediaContainer: nil,
            playShuffled: false,
            playbackRepeatMode: .none,
            resumePlayback: true,
            playbackQueueLocation: .now,
            playbackSpeed: Double(playbackRate),
            mediaSearch: nil)
        
        let activityType: String
        let userInfo: [String: Any]
        
        switch item {
            case is Audiobook:
                activityType = "audiobook"
                userInfo = [
                    "audiobookId": item.id,
                ]
            case is Episode:
                activityType = "episode"
                userInfo = [
                    "episodeId": item.id,
                    "podcastId": (item as! Episode).podcastId,
                ]
            default:
                activityType = "unknown"
                userInfo = [:]
        }
        
        let activity = NSUserActivity(activityType: "io.rfk.shelfplayer.\(activityType)")
        
        activity.title = item.name
        activity.persistentIdentifier = convertIdentifier(item: item)
        activity.targetContentIdentifier = "\(activityType):\(item.id)"
        
        activity.isEligibleForPrediction = true
        activity.userInfo = userInfo
        
        activity.isEligibleForHandoff = true
        
        let interaction = INInteraction(intent: intent, response: INPlayMediaIntentResponse(code: .success, userActivity: activity))
        try await interaction.donate()
    }
}

internal extension AudioPlayer {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
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
