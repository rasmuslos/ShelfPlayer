//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation
import SPFoundation

internal extension AudiobookshelfClient {
    func item(itemId: String) async throws -> AudiobookshelfItem {
        try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(itemId)", method: "GET", query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension AudiobookshelfClient {
    func item(itemId: String, episodeId: String?) async throws -> (PlayableItem, [PlayableItem.AudioTrack], [PlayableItem.Chapter]) {
        let response = try await item(itemId: itemId)
        
        if let episodeId = episodeId, let item = response.media?.episodes?.first(where: { $0.id == episodeId }) {
            let episode = Episode(episode: item, item: response)
            
            guard let episode, let audioTrack = item.audioTrack, let chapters = item.chapters else {
                throw ClientError.invalidResponse
            }
            
            return (episode, [.init(track: audioTrack)], chapters.map(PlayableItem.Chapter.init))
        }
        
        guard let audiobook = Audiobook(item: response), let tracks = response.media?.tracks, let chapters = response.media?.chapters else {
            throw ClientError.invalidResponse
        }
        
        return (audiobook, tracks.map(PlayableItem.AudioTrack.init), chapters.map(PlayableItem.Chapter.init))
    }
    
    func items(search: String, libraryID: String) async throws -> ([Audiobook], [Podcast], [Author], [Series]) {
        let response = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryID)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: search),
        ]))
        
        return (
            response.book?.compactMap { Audiobook(item: $0.libraryItem) } ?? [],
            response.podcast?.map { Podcast(item: $0.libraryItem) } ?? [],
            response.authors?.map(Author.init) ?? [],
            response.series?.map { Series(item: $0.series, audiobooks: $0.books) } ?? []
        )
    }
}

public extension AudiobookshelfClient {
    func createBookmark(itemId: String, position: TimeInterval, note: String) async throws -> Bookmark {
        try await request(ClientRequest<Bookmark>(path: "api/me/item/\(itemId)/bookmark", method: "POST", body: [
            "title": note,
            "time": Int(position),
        ]))
    }
    func updateBookmark(itemId: String, position: TimeInterval, note: String) async throws -> Bookmark {
        try await request(ClientRequest<Bookmark>(path: "api/me/item/\(itemId)/bookmark", method: "PATCH", body: [
            "title": note,
            "time": Int(position),
        ]))
    }
    
    func deleteBookmark(itemId: String, position: TimeInterval) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/item/\(itemId)/bookmark/\(Int(position))", method: "DELETE"))
    }
}
