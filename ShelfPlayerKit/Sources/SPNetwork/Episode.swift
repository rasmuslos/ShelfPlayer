//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient where I == ItemIdentifier.ConnectionID  {
    func episodes(from identifier: ItemIdentifier) async throws -> [Episode] {
        let item = try await response(for: ClientRequest<ItemPayload>(path: "api/items/\(identifier.pathComponent)", method: .get))
        
        guard let episodes = item.media?.episodes else {
            throw APIClientError.invalidResponse
        }
        
        return episodes.compactMap { Episode(episode: $0, item: item, connectionID: connectionID) }
    }
    
    func recentEpisodes(from libraryID: String, limit: Int) async throws -> [Episode] {
        try await response(for: ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryID)/recent-episodes", method: .get, query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(describing: limit)),
        ])).episodes.enumerated().map { Episode(episode: $0.element, fallbackIndex: $0.offset, connectionID: connectionID) }
    }
}

