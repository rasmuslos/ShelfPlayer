//
//  OfflineManager+Cleanup.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.10.23.
//

import Foundation
import SwiftData

extension OfflineManager {
    @MainActor
    public func deleteAllDownloads() {
        let audiobooks = getAudiobooks()
        for audiobook in audiobooks {
            try? delete(audiobookId: audiobook.id)
        }
        
        if let tracks = try? PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAudiobookTrack>()) {
            for track in tracks {
                deleteAudiobookTrack(track: track)
            }
        }
        
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: DownloadReference.self)
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflineChapter.self)
        
        let episodes = getEpisodes()
        for episode in episodes {
            try? delete(episodeId: episode.id)
        }
        
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflinePodcast.self)
        try? DownloadManager.shared.cleanupDirectory()
    }
    
    @MainActor
    public func deleteOfflineProgress() {
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflinePodcast.self)
    }
}
