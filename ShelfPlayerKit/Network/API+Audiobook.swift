//
//  AudiobookshelfClient+Audiobooks.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public extension APIClient {
    func home(for libraryID: String) async throws -> ([HomeRow<Audiobook>], [HomeRow<Person>]) {
        let response = try await response(APIRequest<[HomeRowPayload]>(path: "api/libraries/\(libraryID)/personalized", method: .get, ttl: 12))
        
        var authors = [HomeRow<Person>]()
        var audiobooks = [HomeRow<Audiobook>]()
        
        for row in response {
            if row.entities.isEmpty {
                continue
            }
            
            if row.type == "book" {
                audiobooks.append(HomeRow(id: row.id, label: row.label, entities: row.entities.compactMap { Audiobook(payload: $0, libraryID: libraryID, connectionID: connectionID) }))
            } else if row.type == "authors" {
                authors.append(HomeRow(id: row.id, label: row.label, entities: row.entities.map { Person(author: $0, connectionID: connectionID) }))
            }
        }
        
        return (audiobooks, authors)
    }
    
    func audiobook(with itemID: ItemIdentifier) async throws -> Audiobook {
        try await audiobook(primaryID: itemID.primaryID)
    }
    func audiobook(primaryID: ItemIdentifier.PrimaryID) async throws -> Audiobook {
        let payload = try await item(primaryID: primaryID, groupingID: nil)
        
        guard let audiobook = Audiobook(payload: payload, libraryID: payload.libraryId, connectionID: connectionID) else {
            throw APIClientError.invalidItemType
        }
        
        return audiobook
    }
    
    func audiobooks(from libraryID: String, filter: ItemFilter, sortOrder: AudiobookSortOrder, ascending: Bool, groupSeries: Bool = false, limit: Int?, page: Int?) async throws -> ([AudiobookSection], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: sortOrder.queryValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
            .init(name: "collapseseries", value: groupSeries ? "1" : "0"),
        ]
        
        switch filter {
            case .all:
                break
            case .active:
                query.append(.init(name: "filter", value: "progress.aW4tcHJvZ3Jlc3M%3D"))
            case .finished:
                query.append(.init(name: "filter", value: "progress.ZmluaXNoZWQ%3D"))
            case .notFinished:
                query.append(.init(name: "filter", value: "progress.bm90LWZpbmlzaGVk"))
        }
        
        if let page {
            query.append(.init(name: "page", value: String(describing: page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(describing: limit)))
        }
        
        let result = try await response(APIRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: .get, query: query, ttl: 12))
        return (result.results.compactMap { AudiobookSection.parse(payload: $0, libraryID: libraryID, connectionID: connectionID) }, result.total)
    }
    func audiobooks(from libraryID: String, filtered genre: String, sortOrder: AudiobookSortOrder, ascending: Bool, groupSeries: Bool = false, limit: Int?, page: Int?) async throws -> ([AudiobookSection], Int) {
        var query: [URLQueryItem] = [
            .init(name: "sort", value: sortOrder.queryValue),
            .init(name: "desc", value: ascending ? "0" : "1"),
            .init(name: "collapseseries", value: groupSeries ? "1" : "0"),
            .init(name: "filter", value: "genres.\(Data(genre.utf8).base64EncodedString())"),
        ]
        
        if let page {
            query.append(.init(name: "page", value: String(describing: page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(describing: limit)))
        }
        
        let result = try await response(APIRequest<ResultResponse>(path: "api/libraries/\(libraryID)/items", method: .get, query: query, ttl: 12))
        return (result.results.compactMap { AudiobookSection.parse(payload: $0, libraryID: libraryID, connectionID: connectionID) }, result.total)
    }
    
    func audiobooks(filtered identifier: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?, groupSeries: Bool = false, limit: Int?, page: Int?) async throws -> ([Audiobook], Int) {
        var query = [URLQueryItem]()
        
        if identifier.type == .author {
            query.append(URLQueryItem(name: "filter", value: "authors.\(Data(identifier.primaryID.utf8).base64EncodedString())"))
        } else if identifier.type == .narrator {
            query.append(URLQueryItem(name: "filter", value: "narrators.\(identifier.primaryID)"))
        } else if identifier.type == .series {
            query.append(URLQueryItem(name: "filter", value: "series.\(Data(identifier.primaryID.utf8).base64EncodedString())"))
        } else {
            throw APIClientError.invalidItemType
        }
        
        if let page {
            query.append(.init(name: "page", value: String(page)))
        }
        if let limit {
            query.append(.init(name: "limit", value: String(limit)))
        }
        
        if let sortOrder {
            query.append(.init(name: "sort", value: sortOrder.queryValue))
        }
        if let ascending {
            query.append(.init(name: "desc", value: ascending ? "0" : "1"))
        }
        
        let result = try await response(APIRequest<ResultResponse>(path: "api/libraries/\(identifier.libraryID)/items", method: .get, query: query, ttl: 12))
        return (result.results.compactMap { Audiobook(payload: $0, libraryID: identifier.libraryID, connectionID: connectionID) }, result.total)
    }
}

