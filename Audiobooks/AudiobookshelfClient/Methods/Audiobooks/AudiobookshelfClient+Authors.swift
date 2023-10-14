//
//  AudiobookshelfClient+Authors.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

// MARK: Search

extension AudiobookshelfClient {
    func getAuthorIdByName(_ name: String, libraryId: String) async -> String? {
        let response = try? await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryId)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "1"),
        ]))
        
        return response?.authors?.first?.id
    }
}

// MARK: Get author

extension AudiobookshelfClient {
    func getAuthorData(authorId: String, libraryId: String) async throws -> (Author, [Audiobook], [Series]) {
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: "api/authors/\(authorId)", method: "GET", query: [
            URLQueryItem(name: "library", value: libraryId),
            URLQueryItem(name: "include", value: "items,series"),
        ]))
        
        let author = Author.convertFromAudiobookshelf(item: response)
        let audiobooks = (response.libraryItems ?? []).map(Audiobook.convertFromAudiobookshelf)
        let series = (response.series ?? []).map(Series.convertFromAudiobookshelf)
        
        return (author, audiobooks, series)
    }
}

// MARK: Get audiobooks by author

extension AudiobookshelfClient {
    func getAudiobooksByAuthor(authorId: String, libraryId: String) async throws -> [Audiobook] {
        try await getAuthorData(authorId: authorId, libraryId: libraryId).1
    }
}
