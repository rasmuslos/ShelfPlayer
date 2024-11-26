//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func episodes(from identifier: ItemIdentifier) async throws -> [Episode] {
        let item = try await request(ClientRequest<ItemPayload>(path: "api/items/\(identifier.pathComponent)", method: "GET"))
        
        guard let episodes = item.media?.episodes else {
            throw ClientError.invalidResponse
        }
        
        return episodes.compactMap { Episode(episode: $0, item: item) }
    }
    
    func recentEpisodes(from libraryID: String, limit: Int) async throws -> [Episode] {
        try await request(ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryID)/recent-episodes", method: "GET", query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(describing: limit)),
        ])).episodes.map(Episode.init)
    }
}

