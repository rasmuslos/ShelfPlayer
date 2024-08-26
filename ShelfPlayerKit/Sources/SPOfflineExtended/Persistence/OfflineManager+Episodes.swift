//
//  OfflineManager+Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData
import SPFoundation
import SPNetwork
import SPOffline

// MARK: Helper

internal extension OfflineManager {
    func offlineEpisode(episodeId: String, context: ModelContext) throws -> OfflineEpisode {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineEpisode> { $0.id == episodeId })
        descriptor.fetchLimit = 1
        
        if let episode = try context.fetch(descriptor).first {
            return episode
        }
        
        throw OfflineError.missing
    }
    
    func offlineEpisodes(context: ModelContext) throws -> [OfflineEpisode] {
        try context.fetch(.init())
    }
    
    func offlineEpisodes(podcastId: String, context: ModelContext) throws -> [OfflineEpisode] {
        try context.fetch(.init()).filter { $0.podcast.id == podcastId }
    }
}

// MARK: Public

public extension OfflineManager {
    func episode(episodeId: String) throws -> Episode {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try Episode(offlineEpisode(episodeId: episodeId, context: context))
    }
    
    func episodes(query: String) throws -> [Episode] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<OfflineEpisode>(predicate: #Predicate { $0.name.localizedStandardContains(query) })
        
        return try context.fetch(descriptor).map(Episode.init)
    }
    
    func episodes(podcastId: String) throws -> [Episode] {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        return try offlineEpisodes(podcastId: podcastId, context: context).map(Episode.init)
    }
    
    func download(episodeId: String, podcastId: String) async throws {
        let (item, tracks, chapters) = try await AudiobookshelfClient.shared.item(itemId: podcastId, episodeId: episodeId)
        let (podcast, _) = try await AudiobookshelfClient.shared.podcast(podcastId: podcastId)
        
        guard let episode = item as? Episode else {
            throw OfflineError.fetchFailed
        }
        
        try await DownloadManager.shared.download(cover: podcast.cover, itemId: podcast.id)
        
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let offlinePodcast = offlinePodcast(podcast: podcast, context: context)
        
        guard ((try? offlineEpisode(episodeId: episodeId, context: context)) ?? nil) == nil else {
            logger.error("Audiobook is already downloaded")
            throw OfflineError.existing
        }
        
        let offlineEpisode = OfflineEpisode(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            overview: episode.description,
            addedAt: episode.addedAt,
            released: episode.released,
            podcast: offlinePodcast,
            index: episode.index,
            duration: episode.duration)
        
        context.insert(offlineEpisode)
        
        storeChapters(chapters, itemId: episode.id, context: context)
        download(tracks: tracks, for: episode.id, type: .episode, context: context)
        
        try context.save()
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episode.id)
    }
    
    func remove(episodeId: String) {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        
        let podcastId: String?
        
        if let episode = try? offlineEpisode(episodeId: episodeId, context: context) {
            podcastId = episode.podcast.id
            context.delete(episode)
        } else {
            podcastId = nil
        }
        
        if let podcastId, let episodes = try? offlineEpisodes(podcastId: podcastId, context: context), episodes.isEmpty {
            remove(podcastId: podcastId)
        }
        
        if let tracks = try? offlineTracks(parentId: episodeId, context: context) {
            for track in tracks {
                remove(track: track, context: context)
            }
        }
        
        try? removeChapters(itemId: episodeId, context: context)
        try? context.save()
        
        if let podcastId {
            removePlaybackSpeedOverride(for: podcastId, episodeID: episodeId)
        }
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episodeId)
    }
}
