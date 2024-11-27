//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation
import SPFoundation

extension AudiobookshelfClient {
    func item(itemID: ItemIdentifier) async throws -> ItemPayload {
        try await request(ClientRequest(path: "api/items/\(itemID.apiItemID)", method: "GET", query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension AudiobookshelfClient {
    func playableItem(itemID: ItemIdentifier) async throws -> (PlayableItem, [PlayableItem.AudioTrack], [Chapter]) {
        let payload = try await item(itemID: itemID)
        
        if itemID.groupingID != nil, let item = payload.media?.episodes?.first(where: { $0.id == itemID.primaryID }) {
            let episode = Episode(episode: item, item: payload)
            
            guard let episode, let audioTrack = item.audioTrack, let chapters = item.chapters else {
                throw ClientError.invalidResponse
            }
            
            return (episode, [.init(track: audioTrack)], chapters.map(Chapter.init))
        }
        
        guard let audiobook = Audiobook(payload: payload), let tracks = payload.media?.tracks, let chapters = payload.media?.chapters else {
            throw ClientError.invalidResponse
        }
        
        return (audiobook, tracks.map(PlayableItem.AudioTrack.init), chapters.map(Chapter.init))
    }
    
    func items(in libraryID: String, search: String) async throws -> ([Audiobook], [Podcast], [Author], [Series]) {
        let payload = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: search),
        ]))
        
        return (
            payload.book?.compactMap { Audiobook(payload: $0.libraryItem) } ?? [],
            payload.podcast?.map { Podcast(payload: $0.libraryItem) } ?? [],
            payload.authors?.map(Author.init) ?? [],
            payload.series?.map { Series(item: $0.series, audiobooks: $0.books) } ?? []
        )
    }
}
