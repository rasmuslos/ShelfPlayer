//
//  AudiobookshelfClient+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func seriesID(name: String, libraryID: String) async throws -> String {
        let response = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "10"),
        ]))
        
        let series = response.series?.compactMap { $0.series }.sorted {
            guard let lhs = $0.name else { return false }
            guard let rhs = $1.name else { return true }
            
            return lhs.levenshteinDistanceScore(to: name) > rhs.levenshteinDistanceScore(to: name)
        }
        
        guard let series = series?.first else {
            throw ClientError.invalidResponse
        }
        
        return series.id
    }
    
    func series(seriesId: String, libraryID: String) async throws -> Series {
        Series(item: try await request(ClientRequest<AudiobookshelfItem>(path: "api/libraries/\(libraryID)/series/\(seriesId)", method: "GET")))
    }
    
    func series(libraryID: String, limit: Int?, page: Int?) async throws -> ([Series], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: "name"),
            .init(name: "desc", value: "0"),
            .init(name: "filter", value: "all"),
        ]
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/series", method: "GET", query: query))
        return (response.results.map(Series.init), response.total)
    }
    
    func audiobooks(seriesId: String, libraryID: String, sortOrder: AudiobookSortOrder, ascending: Bool, limit: Int?, page: Int?) async throws -> ([Audiobook], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: sortOrder.rawValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
            .init(name: "filter", value: "series.\(seriesId.base64)"),
        ]
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: "GET", query: query))
        return (response.results.compactMap(Audiobook.init), response.total)
    }
}
