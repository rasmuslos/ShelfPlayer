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
    func getPodcasts() throws -> [Podcast: [Episode]] {
        let episodes = try getOfflineEpisodes()
        var podcastIds = Set<String>()
        
        for episode in episodes {
            podcastIds.insert(episode.podcast.id)
        }
        
        let podcasts = try podcastIds.map(getOfflinePodcast)
        var result = [Podcast: [Episode]]()
        
        for podcast in podcasts {
            let podcast = Podcast.convertFromOffline(podcast: podcast)
            let episodes = episodes.filter { $0.podcast.id == podcast.id }.map(Episode.convertFromOffline)
            
            result[podcast] = episodes
            podcast.episodeCount = episodes.count
        }
        
        return result
    }
    
    @MainActor
    func getEpisodes(podcastId: String) throws -> [Episode] {
        try getOfflineEpisodes(podcastId: podcastId).map(Episode.convertFromOffline)
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
    
    @MainActor
    func delete(podcastId: String) throws {
        let episodes = try getOfflineEpisodes().filter { $0.podcast.id == podcastId }
        for episode in episodes {
            delete(episodeId: episode.id)
        }
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
    
    @MainActor
    func getOfflinePodcast(podcastId: String) throws -> OfflinePodcast {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePodcast> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        
        if let podcast = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return podcast
        }
        
        throw OfflineError.missing
    }
    
    @MainActor
    func isDownloadFinished(episodeId: String) -> Bool {
        if let track = try? getOfflineTracks(parentId: episodeId).first {
            return isDownloadFinished(track: track)
        }
        
        return false
    }
    
    @MainActor
    func requirePodcast(podcastId: String) async throws -> OfflinePodcast {
        if let podcast = try? getOfflinePodcast(podcastId: podcastId) {
            return podcast
        }
        
        let (podcast, _) = try await AudiobookshelfClient.shared.getPodcast(podcastId: podcastId)
        try await DownloadManager.shared.downloadImage(itemId: podcast.id, image: podcast.image)
        
        let offlinePodcast = OfflinePodcast(
            id: podcast.id,
            libraryId: podcast.libraryId,
            name: podcast.name,
            author: podcast.author,
            overview: podcast.description,
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: podcast.episodeCount)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlinePodcast)
        return offlinePodcast
    }
}
