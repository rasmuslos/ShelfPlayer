//
//  AudiobookshelfClient+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient where I == ItemIdentifier.ConnectionID {
    func seriesID(name: String, libraryID: String) async throws -> ItemIdentifier {
        let response = try await response(for: ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: .get, query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "10"),
        ]))
        
        let series = response.series?.compactMap { $0.series }.sorted {
            guard let lhs = $0.name else { return false }
            guard let rhs = $1.name else { return true }
            
            return lhs.levenshteinDistanceScore(to: name) > rhs.levenshteinDistanceScore(to: name)
        }
        
        guard let series = series?.first else {
            throw APIClientError.invalidResponse
        }
        
        return .init(primaryID: series.id,
                     groupingID: nil,
                     libraryID: libraryID,
                     connectionID: connectionID,
                     type: .series)
    }
    
    func series(with identifier: ItemIdentifier) async throws -> Series {
        Series(payload: try await response(for: ClientRequest<ItemPayload>(path: "api/libraries/\(identifier.libraryID)/series/\(identifier.primaryID)", method: .get)), libraryID: identifier.libraryID, connectionID: connectionID)
    }
    
    func series(in libraryID: String, filtered identifier: ItemIdentifier? = nil, sortOrder: SeriesSortOrder, ascending: Bool, limit: Int?, page: Int?) async throws -> ([Series], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: sortOrder.queryValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
        ]
        
        if let identifier {
            let prefix: String
            
            if identifier.type == .author {
                prefix = "authors"
            } else if identifier.type == .series {
                prefix = "series"
            } else {
                throw APIClientError.missing
            }
            
            query.append(.init(name: "filter", value: "\(prefix).\(Data(identifier.primaryID.utf8).base64EncodedString())"))
        } else {
            query.append(.init(name: "filter", value: "all"))
        }
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        let response = try await response(for: ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/series", method: .get, query: query))
        return (response.results.map { Series(payload: $0, libraryID: libraryID, connectionID: connectionID) }, response.total)
    }
}
