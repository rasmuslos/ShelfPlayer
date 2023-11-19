//
//  OfflineManager+Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

// MARK: Download

extension OfflineManager {
    @MainActor
    public func downloadEpisode(_ episode: Episode) async throws {
        if getEpisode(episodeId: episode.id) != nil {
            logger.error("Episode is already downloaded")
            return
        }
        
        let offlineEpisode = OfflineEpisode(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            overview: episode.description,
            addedAt: episode.addedAt,
            released: episode.released,
            index: episode.index,
            duration: episode.duration)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineEpisode)
        
        // the request can take quite some time to complete and this way the user cannot start multiple downloads
        if let (track, chapters) = try? await AudiobookshelfClient.shared.getEpisodeDownloadData(podcastId: episode.podcastId, episodeId: episode.id), let podcast = try? await getOrCreatePodcast(podcastId: episode.podcastId) {
            
            offlineEpisode.podcast = podcast
            await storeChapters(chapters, itemId: episode.id)
            
            let reference = DownloadReference(reference: episode.id, type: .episode)
            PersistenceManager.shared.modelContainer.mainContext.insert(reference)
            
            let task = DownloadManager.shared.downloadTrack(track: track)
            
            reference.downloadTask = task.taskIdentifier
            task.resume()
            
            NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episode.id)
        } else {
            try deleteEpisode(episodeId: episode.id)
        }
    }
}

// MARK: Getter

extension OfflineManager {
    @MainActor
    func getEpisode(episodeId: String) -> OfflineEpisode? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflineEpisode> { $0.id == episodeId })
        descriptor.fetchLimit = 1
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
}

// MARK: Podcasts

extension OfflineManager {
    @MainActor
    func getOrCreatePodcast(podcastId: String) async throws -> OfflinePodcast {
        if let podcast = getOfflinePodcast(podcastId: podcastId) {
            return podcast
        }
        
        if let (podcast, _) = await AudiobookshelfClient.shared.getPodcastById(podcastId) {
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
        } else {
            throw OfflineError.fetchFailed
        }
    }
    
    @MainActor
    func getOfflinePodcast(podcastId: String) -> OfflinePodcast? {
        var descriptor = FetchDescriptor(predicate: #Predicate<OfflinePodcast> { $0.id == podcastId })
        descriptor.fetchLimit = 1
        return try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor).first
    }
    
    @MainActor
    func getEpisodeOfflineStatus(episodeId: String) -> PlayableItem.OfflineStatus {
        if let episode = getEpisode(episodeId: episodeId) {
            return episode.downloadCompleted ? .downloaded : .working
        } else {
            return .none
        }
    }
}

// MARK: public getter

public extension OfflineManager {
    @MainActor
    func getAllEpisodes() -> [Episode] {
        let descriptor = FetchDescriptor<OfflineEpisode>()
        if let episodes = (try? PersistenceManager.shared.modelContainer.mainContext.fetch(descriptor))?.map(Episode.convertFromOffline) {
            return episodes
        }
        
        return []
    }
    
    @MainActor func getPodcast(podcastId: String) -> Podcast? {
        if let podcast = getOfflinePodcast(podcastId: podcastId) {
            return Podcast.convertFromOffline(podcast: podcast)
        }
        
        return nil
    }
}

// MARK: delete

extension OfflineManager {
    @MainActor
    public func deleteEpisode(episodeId: String) throws {
        if let episode = getEpisode(episodeId: episodeId) {
            PersistenceManager.shared.modelContainer.mainContext.delete(episode)
        }
        
        // i don't think there is a way to delete the podcast...
        
        DownloadManager.shared.deleteEpisode(episodeId: episodeId)
        try deleteChapters(itemId: episodeId)
        
        NotificationCenter.default.post(name: PlayableItem.downloadStatusUpdatedNotification, object: episodeId)
    }
}
