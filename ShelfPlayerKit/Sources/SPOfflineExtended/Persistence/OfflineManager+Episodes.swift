//
//  OfflineManager+Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData
import SPBase
import SPOffline

public extension OfflineManager {
    @MainActor
    func getEpisodes(query: String) throws -> [Episode] {
        let descriptor = FetchDescriptor<OfflineEpisode>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(Episode.convertFromOffline)
    }
    
    @MainActor
    func getEpisode(episodeId: String) throws -> Episode {
        try Episode.convertFromOffline(episode: getOfflineEpisode(episodeId: episodeId))
    }
    
    @MainActor
    func download(episodeId: String, podcastId: String) async throws {
        if (try? getOfflineEpisode(episodeId: episodeId)) != nil {
            logger.error("Episode is already downloaded")
            return
        }
        
        let (item, tracks, chapters) = try await AudiobookshelfClient.shared.getItem(itemId: podcastId, episodeId: episodeId)
        let podcast = try await requirePodcast(podcastId: podcastId)
        
        guard let episode = item as? Episode else { throw OfflineError.fetchFailed }
        
        let offlineEpisode = OfflineEpisode(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            overview: episode.description,
            addedAt: episode.addedAt,
            released: episode.released,
            podcast: podcast,
            index: episode.index,
            duration: episode.duration)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineEpisode)
        
        await storeChapters(chapters, itemId: episode.id)
        download(itemId: episode.id, tracks: tracks, type: .episode)
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episode.id)
    }
    
    @MainActor
    func isDownloadFinished(episodeId: String) -> Bool {
        if let track = try? getOfflineTracks(parentId: episodeId).first {
            return isDownloadFinished(track: track)
        }
        
        return false
    }
    
    @MainActor
    func delete(episodeId: String) {
        if let episode = try? getOfflineEpisode(episodeId: episodeId) {
            let podcastId = episode.podcast.id
            PersistenceManager.shared.modelContainer.mainContext.delete(episode)
            
            // there is only a bad way to delete the podcast so i will not do it
            logger.warning("Podcast may be orphaned: \(podcastId)")
        }
        
        if let tracks = try? getOfflineTracks(parentId: episodeId) {
            for track in tracks {
                delete(track: track)
            }
        }
        
        deleteChapters(itemId: episodeId)
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episodeId)
    }
}



extension OfflineManager {
    @MainActor
    func getOfflineEpisode(episodeId: String) throws -> OfflineEpisode {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineEpisode> { $0.id == episodeId })
        descriptor.fetchLimit = 1
        
        if let episode = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return episode
        }
        
        throw OfflineError.missing
    }
    
    @MainActor
    func getOfflineEpisodes() throws -> [OfflineEpisode] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor())
    }
    
    @MainActor
    func getOfflineEpisodes(podcastId: String) throws -> [OfflineEpisode] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor()).filter { $0.podcast.id == podcastId }
    }
}
