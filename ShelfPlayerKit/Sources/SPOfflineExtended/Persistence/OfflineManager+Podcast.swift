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

// MARK: Internal

internal extension OfflineManager {
    func offlinePodcast(podcast: Podcast, context: ModelContext) -> OfflinePodcast {
        if let podcast = try? offlinePodcast(podcastId: podcast.id, context: context) {
            return podcast
        }
        
        let offlinePodcast = OfflinePodcast(
            id: podcast.id,
            libraryId: podcast.libraryID,
            name: podcast.name,
            author: podcast.author,
            overview: podcast.description,
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: podcast.episodeCount)
        
        context.insert(offlinePodcast)
        return offlinePodcast
    }
    
    func offlinePodcast(podcastId: String, context: ModelContext) throws -> OfflinePodcast {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePodcast> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        
        if let podcast = try context.fetch(descriptor).first {
            return podcast
        }
        
        throw OfflineError.missing
    }
    
    func offlinePodcasts(context: ModelContext) throws -> [OfflinePodcast] {
        try context.fetch(.init())
    }
}

// MARK: Public

public extension OfflineManager {
    func podcasts() throws -> [Podcast: [Episode]] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let episodes = try offlineEpisodes(context: context)
        let podcasts = try offlinePodcasts(context: context)
        
        var result = [Podcast: [Episode]]()
        
        for podcast in podcasts {
            let podcast = Podcast(podcast)
            let episodes = episodes.filter { $0.podcast.id == podcast.id }.map(Episode.init)
            
            result[podcast] = episodes
            podcast.episodeCount = episodes.count
        }
        
        return result.filter {
            if $0.value.isEmpty {
                remove(podcastId: $0.key.id)
                return false
            }
            
            return true
        }
    }
    
    func podcast(podcastId: String) throws -> Podcast {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try Podcast(offlinePodcast(podcastId: podcastId, context: context))
    }
    
    func podcasts(query: String) throws -> [Podcast] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflinePodcast>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        
        return try context.fetch(descriptor).map(Podcast.init)
    }
    
    func remove(podcastId: String) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        if let episodes = try? offlineEpisodes(podcastId: podcastId, context: context) {
            for episode in episodes {
                remove(episodeId: episode.id, allowPodcastDeletion: false)
            }
        }
        
        if let podcast = try? offlinePodcast(podcastId: podcastId, context: context) {
            context.delete(podcast)
        }
        
        // Disabled for now
        // resetConfiguration(for: podcastId, context: context)
        
        try? context.save()
    }
}

// MARK: Fetch configurations

public extension OfflineManager {
    @MainActor
    func requireConfiguration(podcastId: String) -> PodcastFetchConfiguration {
        let context = PersistenceManager.shared.modelContainer.mainContext
        
        if let configuration = try? getConfiguration(podcastId: podcastId, context: context) {
            return configuration
        }
        
        let configuration = PodcastFetchConfiguration(id: podcastId)
        
        context.insert(configuration)
        try? context.save()
        
        return configuration
    }
    
    func getConfigurations(active: Bool) throws -> [PodcastFetchConfiguration] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try context.fetch(FetchDescriptor<PodcastFetchConfiguration>(predicate: #Predicate { $0.autoDownload == active }))
    }
}

internal extension OfflineManager {
    func getConfiguration(podcastId: String, context: ModelContext) throws -> PodcastFetchConfiguration {
        var descriptor = FetchDescriptor(predicate: #Predicate<PodcastFetchConfiguration> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        
        if let configuration = try context.fetch(descriptor).first {
            return configuration
        }
        
        throw OfflineError.missing
    }
    
    func resetConfiguration(for podcastId: String, context: ModelContext) {
        guard let configuration = try? getConfiguration(podcastId: podcastId, context: context) else {
            return
        }
        
        configuration.maxEpisodes = 3
        configuration.autoDownload = false
        configuration.notifications = false
        
        try? context.save()
    }
}
