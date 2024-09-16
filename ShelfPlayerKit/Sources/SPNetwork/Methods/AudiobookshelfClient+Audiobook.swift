//
//  AudiobookshelfClient+Audiobooks.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func home(libraryId: String) async throws -> ([HomeRow<Audiobook>], [HomeRow<Author>]) {
        let response = try await request(ClientRequest<[AudiobookshelfHomeRow]>(path: "api/libraries/\(libraryId)/personalized", method: "GET"))
        
        var authors = [HomeRow<Author>]()
        var audiobooks = [HomeRow<Audiobook>]()
        
        for row in response {
            if row.entities.isEmpty {
                continue
            }
            
            if row.type == "book" {
                audiobooks.append(HomeRow(id: row.id, label: row.label, entities: row.entities.compactMap(Audiobook.init)))
            } else if row.type == "authors" {
                authors.append(HomeRow(id: row.id, label: row.label, entities: row.entities.map(Author.init)))
            }
        }
        
        return (audiobooks, authors)
    }
    
    func audiobooks(libraryId: String, sortOrder: String, limit: Int, page: Int) async throws -> ([Audiobook], Int) {
        let result = try await request(ClientRequest<ResultResponse>(path: "api/libraries/\(libraryId)/items", method: "GET", query: [
            .init(name: "page", value: "\(page)"),
            .init(name: "limit", value: "\(limit)"),
            .init(name: "sort", value: "\(sortOrder)"),
        ]))
        
        return (result.results.compactMap(Audiobook.init), result.total)
    }
}
