//
//  AudiobookshelfClient+Audiobooks.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension AudiobookshelfClient {
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
    
    func getAudiobooks(libraryId: String) async throws -> [Audiobook] {
        let response = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET"))
        return response.results.map(Audiobook.convertFromAudiobookshelf)
    }
}

extension AudiobookshelfClient {
    func getAudiobookDownloadData(_ audiobookId: String) async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters) {
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(audiobookId)", method: "GET", query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
        
        let tracks = response.media!.tracks!.map(PlayableItem.convertAudioTrackFromAudiobookshelf)
        let chapters = response.media!.chapters!.map(PlayableItem.convertChapterFromAudiobookshelf)
        
        return (tracks, chapters)
    }
}
