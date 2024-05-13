//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 13.05.24.
//

import Foundation
import Defaults
import SPBase
#if canImport(SPOffline)
import SPOffline
#endif

extension AudioPlayer {
    public static func nextEpisode(podcastId: String) async -> (Podcast, Episode)? {
        if !Defaults[.podcastNextUp] {
            return nil
        }
        
        if let podcast = try? await OfflineManager.shared.getPodcast(podcastId: podcastId), let episodes = try? await OfflineManager.shared.getEpisodes(podcastId: podcastId), !episodes.isEmpty {
            
            if let episode = await AudiobookshelfClient.filterSort(episodes: episodes, filter: Defaults[.episodesFilter(podcastId: podcast.id)], sortOrder: Defaults[.episodesSort(podcastId: podcast.id)], ascending: Defaults[.episodesAscending(podcastId: podcast.id)]).first {
                return (podcast, episode)
            }
        }
        
        if let (podcast, episodes) = try? await AudiobookshelfClient.shared.getPodcast(podcastId: podcastId), let episode = await AudiobookshelfClient.filterSort(episodes: episodes, filter: Defaults[.episodesFilter(podcastId: podcast.id)], sortOrder: Defaults[.episodesSort(podcastId: podcast.id)], ascending: Defaults[.episodesAscending(podcastId: podcast.id)]).first {
            return (podcast, episode)
        }
        
        return nil
    }
}
