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
        try await request(ClientRequest(path: "api/items/\(itemID.apiItemID)", method: .get, query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension APIClient where I == ItemIdentifier.ServerID  {
    func playableItem(itemID: ItemIdentifier) async throws -> (PlayableItem, [PlayableItem.AudioTrack], [Chapter]) {
        let payload = try await item(itemID: itemID)
        
        if itemID.groupingID != nil, let item = payload.media?.episodes?.first(where: { $0.id == itemID.primaryID }) {
            let episode = Episode(episode: item, item: payload, serverID: serverID)
            
            guard let episode, let audioTrack = item.audioTrack, let chapters = item.chapters else {
                throw APIClientError.invalidResponse
            }
            
            return (episode, [.init(track: audioTrack)], chapters.map(Chapter.init))
        }
        
        guard let audiobook = Audiobook(payload: payload, serverID: itemID.serverID), let tracks = payload.media?.tracks, let chapters = payload.media?.chapters else {
            throw APIClientError.invalidResponse
        }
        
        return (audiobook, tracks.map(PlayableItem.AudioTrack.init), chapters.map(Chapter.init))
    }
    
    func items(in library: Library, search: String) async throws -> ([Audiobook], [Podcast], [Author], [Series]) {
        let payload = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(library.id)/search", method: .get, query: [
            URLQueryItem(name: "q", value: search),
        ]))
        
        return (
            payload.book?.compactMap { Audiobook(payload: $0.libraryItem, serverID: library.serverID) } ?? [],
            payload.podcast?.map { Podcast(payload: $0.libraryItem, serverID: serverID) } ?? [],
            payload.authors?.map { Author(payload: $0, serverID: library.serverID) } ?? [],
            payload.series?.map { Series(item: $0.series, audiobooks: $0.books, serverID: library.serverID) } ?? []
        )
    }
}
