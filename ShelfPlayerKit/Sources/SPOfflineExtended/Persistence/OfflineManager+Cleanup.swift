//
//  OfflineManager+Cleanup.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import Foundation
import SwiftData
import SPOffline

public extension OfflineManager {
    func removeAllDownloads() {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let audiobooks = try? offlineAudiobooks(context: context) {
            for audiobook in audiobooks {
                remove(audiobookId: audiobook.id)
            }
        }
        
        if let episodes = try? offlineEpisodes(context: context) {
            for episode in episodes {
                remove(episodeId: episode.id)
            }
        }
        
        if let podcasts = try? offlinePodcasts(context: context) {
            for podcast in podcasts {
                remove(podcastId: podcast.id)
            }
        }
        
        if let tracks = try? offlineTracks(context: context) {
            for track in tracks {
                remove(track: track, context: context)
            }
        }
        
        try? context.delete(model: OfflineChapter.self)
        try? context.delete(model: OfflineListeningTimeTracker.self)
        
        try? DownloadManager.shared.clearDirectories()
        
        try? context.save()
    }
}
