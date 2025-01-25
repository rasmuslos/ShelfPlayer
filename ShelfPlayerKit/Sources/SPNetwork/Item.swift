//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation
import RFNetwork
import SPFoundation

extension APIClient {
    func item(itemID: ItemIdentifier) async throws -> ItemPayload {
        try await response(for: ClientRequest(path: "api/items/\(itemID.apiItemID)", method: .get, query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension APIClient where I == ItemIdentifier.ConnectionID  {
    func playableItem(itemID: ItemIdentifier) async throws -> (PlayableItem, [PlayableItem.AudioTrack], [Chapter], [PlayableItem.SupplementaryPDF]) {
        let payload = try await item(itemID: itemID)
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
            
            guard let episode,
                  let audioTrack = item.audioTrack,
                  let chapters = item.chapters else {
                throw APIClientError.invalidResponse
            }
            
            return (episode, [.init(track: audioTrack)], chapters.map(Chapter.init), supplementaryPDFs)
        }
        
        guard let audiobook = Audiobook(payload: payload, libraryID: itemID.libraryID, connectionID: itemID.connectionID),
              let tracks = payload.media?.tracks,
              let chapters = payload.media?.chapters else {
            throw APIClientError.invalidResponse
        }
        
        return (audiobook, tracks.map(PlayableItem.AudioTrack.init), chapters.map(Chapter.init), supplementaryPDFs)
    }
    
    func items(in library: Library, search: String) async throws -> ([Audiobook], [Podcast], [Author], [Series]) {
        let payload = try await response(for: ClientRequest<SearchResponse>(path: "api/libraries/\(library.id)/search", method: .get, query: [
            URLQueryItem(name: "q", value: search),
        ]))
        
        return (
            payload.book?.compactMap { Audiobook(payload: $0.libraryItem, libraryID: library.id, connectionID: library.connectionID) } ?? [],
            payload.podcast?.map { Podcast(payload: $0.libraryItem, connectionID: connectionID) } ?? [],
            payload.authors?.map { Author(payload: $0, connectionID: library.connectionID) } ?? [],
            payload.series?.map { Series(item: $0.series, audiobooks: $0.books, libraryID: library.id, connectionID: library.connectionID) } ?? []
        )
    }
    
    func pdf(from itemID: ItemIdentifier, ino: String) async throws -> Data {
        try await URLSession.shared.data(for: try await request(ClientRequest<Data>(path: "api/items/\(itemID.primaryID)/ebook/\(ino)", method: .get))).0
    }
}
