//
//  OfflineManager+Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData
import SPBaseKit
import SPOfflineKit

public extension OfflineManager {
    @MainActor
    func download(episodeId: String, podcastId: String) async throws {
        if (try? getOfflineEpisode(episodeId: episodeId)) != nil {
            logger.error("Episode is already downloaded")
            return
        }
        
        let (item, tracks, chapters) = try await AudiobookshelfClient.shared.getDownloadData(itemId: podcastId, episodeId: episodeId)
        let podcast = try await requirePodcast(podcastId: podcastId)
        
        guard let episode = item as? Episode, let track = tracks.first else { throw OfflineError.fetchFailed }
        
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
        
        let offlineTrack = OfflineTrack(
            id: episode.id,
            parentId: episode.id,
            index: 0,
            fileExtension: track.fileExtension,
            offset: track.offset,
            duration: track.duration,
            type: .audiobook)
        
        PersistenceManager.shared.modelContainer.mainContext.insert(offlineTrack)
        
        let task = DownloadManager.shared.download(track: track)
        offlineTrack.downloadReference = task.taskIdentifier
        
        task.resume()
        
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
