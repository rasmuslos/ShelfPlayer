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
        
        for row in response {
            if row.type == "book" {
                let audiobookRow = AudiobookHomeRow(id: row.id, label: row.label, audiobooks: row.entities.map(Audiobook.convertFromAudiobookshelf))
                audiobookRows.append(audiobookRow)
            }
        }
        
        return (audiobookRows, [])
    }
}
