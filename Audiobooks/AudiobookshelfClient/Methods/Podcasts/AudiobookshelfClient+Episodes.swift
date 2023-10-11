//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

extension AudiobookshelfClient {
    func getLatestEpisodes(libraryId: String) async throws -> [Episode] {
        let response = try await request(ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryId)/recent-episodes", method: "GET", query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "25"),
        ]))
        return response.episodes.map(Episode.convertFromAudiobookshelf)
    }
}
