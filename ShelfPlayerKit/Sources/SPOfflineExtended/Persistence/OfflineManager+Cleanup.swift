//
//  OfflineManager+Cleanup.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import Foundation
import SwiftData
import SPOffline

extension OfflineManager {
    @MainActor
    public func deleteDownloads() {
        if let audiobooks = try? getOfflineAudiobooks() {
            for audiobook in audiobooks {
                delete(audiobookId: audiobook.id)
            }
        }
        
        if let tracks = try? getOfflineTracks() {
            for track in tracks {
                delete(track: track)
            }
        }
        
        if let episodes = try? getOfflineEpisodes() {
            for episode in episodes {
                delete(episodeId: episode.id)
            }
        }
        
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflineChapter.self)
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflinePodcast.self)
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: PlaybackDuration.self)
        
        try? DownloadManager.shared.cleanupDirectory()
    }
}
