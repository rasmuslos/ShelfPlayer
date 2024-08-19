//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 09.02.24.
//

import Foundation
import SwiftData
import SPFoundation
import SPOffline

// MARK: Episode helper

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
    func getPodcasts(query: String) throws -> [Podcast] {
        let descriptor = FetchDescriptor<OfflinePodcast>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        return try PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).map(Podcast.convertFromOffline)
    }
    
    @MainActor
    func getPodcast(podcastId: String) throws -> Podcast {
        try Podcast.convertFromOffline(podcast: getOfflinePodcast(podcastId: podcastId))
    }
    
    @MainActor
    func getEpisodes(podcastId: String) throws -> [Episode] {
        try getOfflineEpisodes(podcastId: podcastId).map(Episode.convertFromOffline)
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
    
    @MainActor
    func getOfflinePodcast(podcastId: String) throws -> OfflinePodcast {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePodcast> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        
        if let podcast = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return podcast
        }
        
        throw OfflineError.missing
    }
}

// MARK: Fetch configurations

public extension OfflineManager {
    @MainActor
    func requireConfiguration(podcastId: String) -> PodcastFetchConfiguration {
        if let configuration = try? getConfiguration(podcastId: podcastId) {
            return configuration
        }
        
        let configuration = PodcastFetchConfiguration(id: podcastId)
        PersistenceManager.shared.modelContainer.mainContext.insert(configuration)
        
        return configuration
    }
    
    @MainActor
    func getConfigurations(active: Bool) throws -> [PodcastFetchConfiguration] {
        try PersistenceManager.shared.modelContainer.mainContext.fetch(FetchDescriptor<PodcastFetchConfiguration>(predicate: #Predicate { $0.autoDownload == active }))
    }
}

extension OfflineManager {
    @MainActor
    func getConfiguration(podcastId: String) throws -> PodcastFetchConfiguration {
        var descriptor = FetchDescriptor(predicate: #Predicate<PodcastFetchConfiguration> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        
        if let configuration = try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first {
            return configuration
        }
        
        throw OfflineError.missing
    }
}
