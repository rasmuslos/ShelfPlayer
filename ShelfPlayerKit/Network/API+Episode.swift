//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

public extension APIClient {
    func episode(itemID: ItemIdentifier) async throws -> Episode {
        guard let groupingID = itemID.groupingID else {
            throw APIClientError.invalidItemType
        }
        
        return try await episode(primaryID: itemID.primaryID, groupingID: groupingID, libraryID: itemID.libraryID)
    }
    func episode(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID, libraryID: ItemIdentifier.LibraryID) async throws -> Episode {
        try await Episode(episode: response(APIRequest(path: "api/podcasts/\(groupingID)/episode/\(primaryID)", method: .get, ttl: 12)), libraryID: libraryID, fallbackIndex: 0, connectionID: connectionID)
    }
    
    func recentEpisodes(from libraryID: String, limit: Int) async throws -> [Episode] {
        try await response(APIRequest<EpisodesResponse>(path: "api/libraries/\(libraryID)/recent-episodes", method: .get, query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: String(describing: limit)),
        ])).episodes.enumerated().map { Episode(episode: $0.element, libraryID: libraryID, fallbackIndex: $0.offset, connectionID: connectionID) }
    }
}

