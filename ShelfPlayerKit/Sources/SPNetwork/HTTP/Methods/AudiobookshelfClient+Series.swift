//
//  AudiobookshelfClient+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

// MARK: Search

public extension AudiobookshelfClient {
    func getSeriesId(name: String, libraryId: String) async throws -> String {
        let response = try? await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryId)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "10"),
        ]))
        
        let series = response?.series?.compactMap { $0.series }.sorted {
            guard let lhs = $0.name else { return false }
            guard let rhs = $1.name else { return true }
            
            return lhs.levenshteinDistanceScore(to: name) > rhs.levenshteinDistanceScore(to: name)
        }
        
        if let series = series?.first {
            return series.id
        }
        
        throw AudiobookshelfClientError.invalidResponse
    }
    
    func getSeries(seriesId: String, libraryId: String) async -> Series? {
        if let item = try? await request(ClientRequest<AudiobookshelfItem>(path: "api/libraries/\(libraryId)/series/\(seriesId)", method: "GET")) {
            return Series.convertFromAudiobookshelf(item: item)
        }
        
        return nil
    }
    
    func getSeries(libraryId: String) async throws -> [Series] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/series", method: "GET", query: [
            URLQueryItem(name: "sort", value: "name"),
            URLQueryItem(name: "desc", value: "0"),
            URLQueryItem(name: "filter", value: "all"),
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "10000"),
        ]))
        return response.results.map(Series.convertFromAudiobookshelf)
    }
    
    func getAudiobooks(seriesId: String, libraryId: String) async throws -> [Audiobook] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET", query: [
            URLQueryItem(name: "filter", value: "series.\(seriesId.base64)"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "page", value: "0"),
        ]))
        return response.results.compactMap(Audiobook.convertFromAudiobookshelf)
    }
}
