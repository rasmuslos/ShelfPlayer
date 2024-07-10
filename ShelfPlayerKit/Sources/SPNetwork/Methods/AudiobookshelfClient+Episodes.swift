//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func episodes(podcastId: String) async throws -> [Episode] {
        let item = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(podcastId)", method: "GET"))
        
        guard let episodes = item.media?.episodes else {
            throw ClientError.invalidResponse
        }
        
        return episodes.map(Episode.init)
    }
    
    func recentEpisodes(limit: Int, libraryId: String) async throws -> [Episode] {
        try await request(ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryId)/recent-episodes", method: "GET", query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(limit)),
        ])).episodes.map(Episode.init)
    }
}

