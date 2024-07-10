//
//  AudiobookshelfClient+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation
import SPFoundation

// MARK: Search

public extension AudiobookshelfClient {
    func seriesID(name: String, libraryId: String) async throws -> String {
        let response = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryId)/search", method: "GET", query: [
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
    
    func series(seriesId: String, libraryId: String) async throws -> Series {
        Series(item: try await request(ClientRequest<AudiobookshelfItem>(path: "api/libraries/\(libraryId)/series/\(seriesId)", method: "GET")))
    }
    
    func series(libraryId: String) async throws -> [Series] {
        try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/series", method: "GET", query: [
            URLQueryItem(name: "sort", value: "name"),
            URLQueryItem(name: "desc", value: "0"),
            URLQueryItem(name: "filter", value: "all"),
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "10000"),
        ])).results.map(Series.init)
    }
    
    func audiobooks(seriesId: String, libraryId: String) async throws -> [Audiobook] {
        try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET", query: [
            URLQueryItem(name: "filter", value: "series.\(seriesId.base64)"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "page", value: "0"),
        ])).results.compactMap(Audiobook.init)
    }
}
