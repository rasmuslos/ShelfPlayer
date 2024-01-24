//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPBase

#if canImport(SPOfflineExtended)
import SPOffline
import SPOfflineExtended
#endif

extension PlayableItem {
    public func startPlayback() {
        Task { @MainActor in
            let tracks: AudioTracks
            let chapters: Chapters
            var startTime: Double = 0
            let playbackReporter: PlaybackReporter
            
            #if canImport(SPOfflineExtended)
            if OfflineManager.shared.getOfflineStatus(parentId: id) == .downloaded {
                tracks = try OfflineManager.shared.getTracks(parentId: id)
                chapters = OfflineManager.shared.getChapters(itemId: id)
                
                if let episode = self as? Episode {
                    playbackReporter = PlaybackReporter(itemId: episode.podcastId, episodeId: id, playbackSessionId: nil)
                } else {
                    playbackReporter = PlaybackReporter(itemId: id, episodeId: nil, playbackSessionId: nil)
                }
                
                if let entity = OfflineManager.shared.getProgressEntity(item: self), entity.progress < 1 {
                    startTime = entity.currentTime
                    
                    if entity.lastUpdate.timeIntervalSince(Date()) >= 10 * 60 {
                        startTime -= 30
                    }
                }
                
                AudioPlayer.shared.startPlayback(item: self, tracks: tracks, chapters: chapters, startTime: startTime, playbackReporter: playbackReporter)
                return
            }
            #endif
            
            let playbackSessionId: String
            
            if let episode = self as? Episode {
                (tracks, chapters, startTime, playbackSessionId) = try await AudiobookshelfClient.shared.getPlaybackData(itemId: episode.podcastId, episodeId: id)
                playbackReporter = PlaybackReporter(itemId: episode.podcastId, episodeId: id, playbackSessionId: playbackSessionId)
            } else {
                (tracks, chapters, startTime, playbackSessionId) = try await AudiobookshelfClient.shared.getPlaybackData(itemId: id, episodeId: nil)
                playbackReporter = PlaybackReporter(itemId: id, episodeId: nil, playbackSessionId: playbackSessionId)
            }
            
            AudioPlayer.shared.startPlayback(item: self, tracks: tracks, chapters: chapters, startTime: startTime, playbackReporter: playbackReporter)
        }
    }
}
