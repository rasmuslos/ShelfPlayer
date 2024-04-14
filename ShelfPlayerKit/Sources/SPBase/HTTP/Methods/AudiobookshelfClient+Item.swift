//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation

extension AudiobookshelfClient {
    func getItem(itemId: String, episodeId: String?) async throws -> AudiobookshelfItem {
        try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(itemId)", method: "GET", query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
    }
}

public extension AudiobookshelfClient {
    func createBookmark(itemId: String, position: Double, note: String) async throws -> Bookmark {
        return try await request(ClientRequest<Bookmark>(path: "api/me/item/\(itemId)/bookmark", method: "POST", body: [
            "title": note,
            "time": position,
        ]))
    }
    
    func getItem(itemId: String, episodeId: String?) async throws -> (PlayableItem, PlayableItem.AudioTracks, PlayableItem.Chapters) {
        let response: AudiobookshelfItem = try await getItem(itemId: itemId, episodeId: episodeId)
        
        if let episodeId = episodeId, let episode = response.media?.episodes?.first(where: { $0.id == episodeId }) {
            let item = Episode.convertFromAudiobookshelf(podcastEpisode: episode, item: response)
            let track = PlayableItem.convertAudioTrackFromAudiobookshelf(track: episode.audioTrack!)
            let chapters = episode.chapters!.map(PlayableItem.convertChapterFromAudiobookshelf)
            
            return (item, [track], chapters)
        }
        
        let item = Audiobook.convertFromAudiobookshelf(item: response)
        let tracks = response.media!.tracks!.map(PlayableItem.convertAudioTrackFromAudiobookshelf)
        let chapters = response.media!.chapters!.map(PlayableItem.convertChapterFromAudiobookshelf)
        
        return (item, tracks, chapters)
    }
    
    func getItems(query: String, libraryId: String) async throws -> ([Audiobook], [Podcast], [Author], [Series]) {
        let response = try await request(ClientRequest<SearchResponse>(path: "api/libraries/\(libraryId)/search", method: "GET", query: [
            URLQueryItem(name: "q", value: query),
        ]))
        
        let audiobooks = response.book?.map { Audiobook.convertFromAudiobookshelf(item: $0.libraryItem) }
        let podcasts = response.podcast?.map { Podcast.convertFromAudiobookshelf(item: $0.libraryItem) }
        let authors = response.authors?.map(Author.convertFromAudiobookshelf)
        let series = response.series?.map { Series.convertFromAudiobookshelf(item: $0.series, books: $0.books) }
        
        return (
            audiobooks ?? [],
            podcasts ?? [],
            authors ?? [],
            series ?? []
        )
    }
}
