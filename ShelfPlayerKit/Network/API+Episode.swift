//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

public extension APIClient  {
    func episodes(from identifier: ItemIdentifier) async throws -> [Episode] {
        let item: ItemPayload = try await response(path: "api/items/\(identifier.pathComponent)", method: .get)
        
        guard let episodes = item.media?.episodes else {
            throw APIClientError.notFound
        }
        
        return episodes.compactMap { Episode(episode: $0, item: item, connectionID: connectionID) }
    }
    
    func recentEpisodes(from libraryID: String, limit: Int) async throws -> [Episode] {
        let response: EpisodesResponse = try await response(path: "api/libraries/\(libraryID)/recent-episodes", method: .get, query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(describing: limit)),
        ])
        return response.episodes.enumerated().map { Episode(episode: $0.element, libraryID: libraryID, fallbackIndex: $0.offset, connectionID: connectionID) }
    }
}

