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
        
        #if canImport(SPOfflineExtended)
        if OfflineManager.shared.offlineStatus(parentId: item.id) == .downloaded {
            tracks = try OfflineManager.shared.audioTracks(parentId: item.id)
            chapters = try OfflineManager.shared.chapters(itemId: item.id)
            
            var startTime: TimeInterval = .zero
            
            if let episode = item as? Episode {
                playbackReporter = PlaybackReporter(itemId: episode.podcastId, episodeId: item.id, playbackSessionId: nil)
            } else {
                playbackReporter = PlaybackReporter(itemId: item.id, episodeId: nil, playbackSessionId: nil)
            }
            
            let entity = OfflineManager.shared.progressEntity(item: item)
            if entity.progress < 1 {
                startTime = entity.currentTime
                
                if entity.lastUpdate.timeIntervalSince(Date()) >= 10 * 60 {
                    startTime -= 30
                }
                
                startTime = max(startTime, 0)
            }
            
            return startTime
        }
        #endif
        
        let startTime: TimeInterval
        let playbackSessionId: String
        
        if let episode = item as? Episode {
            (tracks,
             chapters,
             startTime,
             playbackSessionId) = try await AudiobookshelfClient.shared.startPlaybackSession(itemId: episode.podcastId, episodeId: item.id)
            
            playbackReporter = PlaybackReporter(itemId: episode.podcastId, episodeId: item.id, playbackSessionId: playbackSessionId)
        } else {
            (tracks,
             chapters,
             startTime,
             playbackSessionId) = try await AudiobookshelfClient.shared.startPlaybackSession(itemId: item.id, episodeId: nil)
            
            playbackReporter = PlaybackReporter(itemId: item.id, episodeId: nil, playbackSessionId: playbackSessionId)
        }
        
        return startTime
    }
    
    func avPlayerItem(item: PlayableItem, track: PlayableItem.AudioTrack) -> AVPlayerItem {
        #if canImport(SPOfflineExtended)
        if let trackURL = try? OfflineManager.shared.url(for: track, itemId: item.id) {
            return AVPlayerItem(url: trackURL)
        }
        #endif
        
        return AVPlayerItem(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ]))
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
        activity.persistentIdentifier = MediaResolver.shared.convertIdentifier(item: item)
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
