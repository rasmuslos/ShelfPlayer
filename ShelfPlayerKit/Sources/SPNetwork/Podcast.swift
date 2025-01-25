//
//  AudiobookshelfClient+Podcasts.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient where I == ItemIdentifier.ConnectionID {
    func home(for libraryID: String) async throws -> ([HomeRow<Podcast>], [HomeRow<Episode>]) {
        let response = try await response(for: ClientRequest<[HomeRowPayload]>(path: "api/libraries/\(libraryID)/personalized", method: .get))
        
        var episodes = [HomeRow<Episode>]()
        var podcasts = [HomeRow<Podcast>]()
        
        for row in response {
            if row.entities.isEmpty {
                continue
            }
            
            if row.type == "episode" {
                episodes.append(HomeRow(id: row.id, label: row.label, entities: row.entities.compactMap{ Episode(payload: $0, connectionID: connectionID) }))
            } else if row.type == "podcast" {
                podcasts.append(HomeRow(id: row.id, label: row.label, entities: row.entities.map { Podcast(payload: $0, connectionID: connectionID) }))
            }
        }
        
        return (podcasts, episodes)
    }
    
    func podcast(with identifier: ItemIdentifier) async throws -> (Podcast, [Episode]) {
        let item = try await response(for: ClientRequest<ItemPayload>(path: "api/items/\(identifier.pathComponent)", method: .get))
        let podcast = Podcast(payload: item, connectionID: connectionID)
        
        guard let episodes = item.media?.episodes else {
            throw APIClientError.invalidResponse
        }
            
        return (podcast, episodes.compactMap { Episode(episode: $0, item: item, connectionID: connectionID) })
        
    }
    
    func podcasts(from libraryID: String, sortOrder: PodcastSortOrder, ascending: Bool, limit: Int?, page: Int?) async throws -> ([Podcast], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: sortOrder.queryValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
        ]
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        query.append(.init(name: "include", value: "numEpisodesIncomplete"))
        
        let response = try await response(for: ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: .get, query: query))
        return (response.results.map { Podcast(payload: $0, connectionID: connectionID) }, response.total)
    }
}
