//
//  AudiobookshelfClient+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

// MARK: Search

extension AudiobookshelfClient {
    func getSeriesIdByName(_ name: String, libraryId: String) async -> String? {
        let response = try? await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryId)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "1"),
        ]))
        
        return response?.series?.first?.series.id
    }
}

// MARK: Get books in series

extension AudiobookshelfClient {
    func getAudiobooksInSeries(seriesId: String, libraryId: String) async throws -> [Audiobook] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET", query: [
            URLQueryItem(name: "filter", value: "series.\(seriesId.toBase64())"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "page", value: "0"),
        ]))
        return response.results.map(Audiobook.convertFromAudiobookshelf)
    }
}

// MARK: Get series by id

extension AudiobookshelfClient {
    func getSeriesById(_ seriesId: String, libraryId: String) async -> Series? {
        if let item = try? await request(ClientRequest<AudiobookshelfItem>(path: "api/libraries/\(libraryId)/series/\(seriesId)", method: "GET")) {
            return Series.convertFromAudiobookshelf(item: item)
        }
        
        return nil
    }
}

// MARK: Get all series

extension AudiobookshelfClient {
    func getAllSeries(libraryId: String) async throws -> [Series] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/series", method: "GET", query: [
            URLQueryItem(name: "sort", value: "name"),
            URLQueryItem(name: "desc", value: "0"),
            URLQueryItem(name: "filter", value: "all"),
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "10000"),
        ]))
        return response.results.map(Series.convertFromAudiobookshelf)
    }
}
