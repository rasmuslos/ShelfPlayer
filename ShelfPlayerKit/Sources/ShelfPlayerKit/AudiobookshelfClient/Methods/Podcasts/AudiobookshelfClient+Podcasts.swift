//
//  AudiobookshelfClient+Podcasts.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

// MARK: Home

public extension AudiobookshelfClient {
    func getPodcastsHome(libraryId: String) async throws -> ([EpisodeHomeRow], [PodcastHomeRow]) {
        let response = try await request(ClientRequest<[AudiobookshelfHomeRow]>(path: "api/libraries/\(libraryId)/personalized", method: "GET"))
        
        var episodeRows = [EpisodeHomeRow]()
        var podcastRows = [PodcastHomeRow]()
        
        for row in response {
            if row.type == "episode" {
                let episodeRow = EpisodeHomeRow(id: row.id, label: row.label, episodes: row.entities.map(Episode.convertFromAudiobookshelf))
                episodeRows.append(episodeRow)
            } else if row.type == "podcast" {
                let podcastRow = PodcastHomeRow(id: row.id, label: row.label, podcasts: row.entities.map(Podcast.convertFromAudiobookshelf))
                podcastRows.append(podcastRow)
            }
        }
        
        return (episodeRows, podcastRows)
    }
    
    func getPodcast(podcastId: String) async -> (Podcast, [Episode])? {
        if let item = try? await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(podcastId)", method: "GET")) {
            let podcast = Podcast.convertFromAudiobookshelf(item: item)
            let episodes = item.media!.episodes!.map { Episode.convertFromAudiobookshelf(podcastEpisode: $0, item: item) }
            
            return (podcast, episodes)
        }
        
        return nil
    }
    
    func getPodcasts(libraryId: String) async throws -> [Podcast] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET"))
        return response.results.map(Podcast.convertFromAudiobookshelf)
    }
}
