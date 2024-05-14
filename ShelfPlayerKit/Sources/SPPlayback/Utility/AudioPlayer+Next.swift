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
    public static func nextEpisode() async -> (Podcast, Episode)? {
        guard Defaults[.podcastNextUp], let item = AudioPlayer.shared.item as? Episode else {
            return nil
        }
        
        if let podcast = try? await OfflineManager.shared.getPodcast(podcastId: item.podcastId), let episodes = try? await OfflineManager.shared.getEpisodes(podcastId: item.podcastId), !episodes.isEmpty {
            
            if let episode = await AudiobookshelfClient.filterSort(episodes: episodes, filter: Defaults[.episodesFilter(podcastId: podcast.id)], sortOrder: Defaults[.episodesSort(podcastId: podcast.id)], ascending: Defaults[.episodesAscending(podcastId: podcast.id)]).first, episode != item {
                return (podcast, episode)
            }
        }
        
        if let (podcast, episodes) = try? await AudiobookshelfClient.shared.getPodcast(podcastId: item.podcastId), let episode = await AudiobookshelfClient.filterSort(episodes: episodes, filter: Defaults[.episodesFilter(podcastId: podcast.id)], sortOrder: Defaults[.episodesSort(podcastId: podcast.id)], ascending: Defaults[.episodesAscending(podcastId: podcast.id)]).first, episode != item {
            return (podcast, episode)
        }
        
        return nil
    }
}
