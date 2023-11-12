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
    func deleteAllDownloads() {
        let audiobooks = getAllAudiobooks()
        for audiobook in audiobooks {
            try? deleteAudiobook(audiobookId: audiobook.id)
        }
        
        if let tracks = try? PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<OfflineAudiobookTrack>()) {
            for track in tracks {
                deleteAudiobookTrack(track: track)
            }
        }
        
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: DownloadReference.self)
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflineChapter.self)
        
        let episodes = getAllEpisodes()
        for episode in episodes {
            try? deleteEpisode(episodeId: episode.id)
        }
        
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflinePodcast.self)
        try? DownloadManager.shared.cleanupDirectory()
    }
    
    @MainActor
    func deleteOfflineProgress() {
        try? PersistenceManager.shared.modelContainer.mainContext.delete(model: OfflinePodcast.self)
    }
}
