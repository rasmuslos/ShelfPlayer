//
//  AudiobookshelfClient+Audiobooks.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

// MARK: Home

extension AudiobookshelfClient {
    func getAudiobooksHome(libraryId: String) async throws -> ([AudiobookHomeRow], [AuthorHomeRow]) {
        let response = try await request(ClientRequest<[AudiobookshelfHomeRow]>(path: "api/libraries/\(libraryId)/personalized", method: "GET"))
        
        var audiobookRows = [AudiobookHomeRow]()
        var authorRows = [AuthorHomeRow]()
        
        for row in response {
            if row.type == "book" {
                let audiobookRow = AudiobookHomeRow(id: row.id, label: row.label, audiobooks: row.entities.map(Audiobook.convertFromAudiobookshelf))
                audiobookRows.append(audiobookRow)
            } else if row.type == "authors" {
                let authorsRow = AuthorHomeRow(id: row.id, label: row.label, authors: row.entities.map(Author.convertFromAudiobookshelf))
                authorRows.append(authorsRow)
            }
        }
        
        return (audiobookRows, authorRows)
    }
}

// MARK: All audiobooks

extension AudiobookshelfClient {
    func getAllAudiobooks(libraryId: String) async throws -> [Audiobook] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET"))
        return response.results.map(Audiobook.convertFromAudiobookshelf)
    }
}
