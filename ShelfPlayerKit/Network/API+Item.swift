//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation

extension APIClient {
    func item(itemID: ItemIdentifier) async throws -> ItemPayload {
        try await item(primaryID: itemID.primaryID, groupingID: itemID.groupingID)
    }
    func item(primaryID: ItemIdentifier.PrimaryID, groupingID: ItemIdentifier.GroupingID?) async throws -> ItemPayload {
        try await response(APIRequest(path: "api/items/\(groupingID ?? primaryID)", method: .get, query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension APIClient  {
    func playableItem(itemID: ItemIdentifier) async throws -> (PlayableItem, [PlayableItem.AudioFile], [Chapter], [PlayableItem.SupplementaryPDF]) {
        let payload = try await item(primaryID: itemID.primaryID, groupingID: itemID.groupingID)
        var supplementaryPDFs = [PlayableItem.SupplementaryPDF]()
        
        if let libraryFiles = payload.libraryFiles {
            for libraryFile in libraryFiles {
                guard libraryFile.metadata.ext == ".pdf" && (libraryFile.isSupplementary ?? true) else {
                    continue
                }
                
                let supplementaryPDF = PlayableItem.SupplementaryPDF(ino: libraryFile.ino,
                                                                     fileName: libraryFile.metadata.filename,
                                                                     fileExtension: libraryFile.metadata.ext.replacingOccurrences(
                                                                        of: ".",
                                                                        with: "",
                                                                        range: libraryFile.metadata.ext.startIndex..<libraryFile.metadata.ext.index(libraryFile.metadata.ext.startIndex, offsetBy: 1)))
                
                supplementaryPDFs.append(supplementaryPDF)
            }
        }
        
        if itemID.groupingID != nil, let item = payload.media?.episodes?.first(where: { $0.id == itemID.primaryID }) {
            let episode = Episode(episode: item, item: payload, connectionID: connectionID)
            
            guard let episode, let audioTrack = item.audioTrack, let chapters = item.chapters else {
                throw APIClientError.notFound
            }
            
            return (episode, [audioTrack].compactMap(PlayableItem.AudioFile.init), chapters.map(Chapter.init), supplementaryPDFs)
        }
        
        guard let audiobook = Audiobook(payload: payload, libraryID: itemID.libraryID, connectionID: connectionID), let tracks = payload.media?.tracks, let chapters = payload.media?.chapters else {
            throw APIClientError.notFound
        }
        
        return (audiobook, tracks.compactMap(PlayableItem.AudioFile.init), chapters.map(Chapter.init), supplementaryPDFs)
    }
    
    func items(in library: Library, search: String) async throws -> ([Audiobook], [Person], [Person], [Series], [Podcast], [Episode]) {
        let payload = try await response(APIRequest<SearchResponse>(path: "api/libraries/\(library.id)/search", method: .get, query: [
            URLQueryItem(name: "q", value: search),
        ]))
        
        return (
            payload.book?.compactMap { Audiobook(payload: $0.libraryItem, libraryID: library.id, connectionID: connectionID) } ?? [],
            payload.authors?.map { Person(author: $0, connectionID: connectionID) } ?? [],
            payload.narrators?.map { Person(narrator: $0, libraryID: library.id, connectionID: connectionID) } ?? [],
            payload.series?.map { Series(item: $0.series, audiobooks: $0.books, libraryID: library.id, connectionID: connectionID) } ?? [],
            payload.podcast?.map { Podcast(payload: $0.libraryItem, connectionID: connectionID) } ?? [],
            payload.episodes?.compactMap {
                guard let recentEpisode = $0.libraryItem.recentEpisode else {
                    return nil
                }
                
                return Episode(episode: recentEpisode, item: $0.libraryItem, connectionID: connectionID)
            } ?? []
        )
    }
    
    func coverRequest(from itemID: ItemIdentifier, width: Int) async throws -> APIRequest<DataResponse> {
        let path: String
        
        switch itemID.type {
        case .author:
            path = "api/authors/\(itemID.primaryID)/image"
        case .episode:
            path = "api/items/\(itemID.groupingID!)/cover"
        default:
            path = "api/items/\(itemID.primaryID)/cover"
        }
        
        return APIRequest(path: path, method: .get, query: [
            URLQueryItem(name: "width", value: width.description),
        ])
    }
    func cover(from itemID: ItemIdentifier, width: Int) async throws -> Data {
        try await response(coverRequest(from: itemID, width: width)).data
    }
    
    func pdfRequest(from itemID: ItemIdentifier, ino: String) async throws -> APIRequest<DataResponse> {
        APIRequest<DataResponse>(path: "api/items/\(itemID.apiItemID)/ebook/\(ino)", method: .get, ttl: 20)
    }
    func pdf(from itemID: ItemIdentifier, ino: String) async throws -> Data {
        try await response(pdfRequest(from: itemID, ino: ino)).data
    }
    
    func audioTrackRequest(from itemID: ItemIdentifier, ino: String) async throws -> URLRequest {
        try await request(APIRequest<DataResponse>(path: "api/items/\(itemID.apiItemID)/file/\(ino)", method: .get))
    }
}
