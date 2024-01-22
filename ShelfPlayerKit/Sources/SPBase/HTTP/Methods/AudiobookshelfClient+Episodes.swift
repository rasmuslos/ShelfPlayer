//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

public extension AudiobookshelfClient {
    func getEpisodes(limit: Int, libraryId: String) async throws -> [Episode] {
        let response = try await request(ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryId)/recent-episodes", method: "GET", query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]))
        return response.episodes.map(Episode.convertFromAudiobookshelf)
    }
    
    func getEpisodes(podcastId: String) async throws -> [Episode] {
        let item = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(podcastId)", method: "GET"))
        return item.media!.episodes!.map { Episode.convertFromAudiobookshelf(podcastEpisode: $0, item: item) }
    }
}

