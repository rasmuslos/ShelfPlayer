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
    
    func getPlaybackData(itemId: String, episodeId: String?) async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters, Double, String) {
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(itemId)/play\(episodeId == nil ? "" : "/\(episodeId!)")", method: "POST", body: [
            "deviceInfo": [
                "clientName": "Audiobooks iOS",
                "deviceId": clientId,
            ],
            "supportedMimeTypes": [
                "audio/flac",
                "audio/mpeg",
                "audio/mp4",
                "audio/aac",
                "audio/x-aiff",
            ]
        ]))
        
        let tracks = response.audioTracks!.map(PlayableItem.convertAudioTrackFromAudiobookshelf)
        let chapters = response.chapters!.map(PlayableItem.convertChapterFromAudiobookshelf)
        let startTime = response.startTime ?? 0
        let playbackSessionId = response.id
        
        return (tracks, chapters, startTime, playbackSessionId)
    }
    
    func setFinished(itemId: String, episodeId: String?, finished: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(episodeId == nil ? "" : "/\(episodeId!)")", method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
    
    func reportPlaybackUpdate(playbackSessionId: String, currentTime: Double, duration: Double, timeListened: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/session/\(playbackSessionId)/sync", method: "POST", body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
    func reportPlaybackClose(playbackSessionId: String, currentTime: Double, duration: Double, timeListened: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/session/\(playbackSessionId)/close", method: "POST", body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
    
    func updateMediaProgress(itemId: String, episodeId: String?, currentTime: Double, duration: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(episodeId == nil ? "" : "/\(episodeId!)")", method: "PATCH", body: [
            "duration": duration,
            "currentTime": currentTime,
            "progress": currentTime / duration,
            "isFinished": duration - currentTime <= 10,
        ]))
    }
    
    func createSession(itemId: String, episodeId: String?, id: String, timeListened: Double, startTime: Double, currentTime: Double, started: Date, updated: Date) async throws {
        let (item, status, userId): (AudiobookshelfItem, StatusResponse, String) = try await (getItem(itemId: itemId, episodeId: episodeId), status(), userId())
        
        let session = LocalSession(
            id: id,
            userId: userId,
            libraryId: item.libraryId,
            libraryItemId: itemId,
            episodeId: episodeId,
            mediaType: item.mediaType,
            mediaMetadata: item.media?.metadata,
            chapters: item.chapters,
            displayTitle: item.media?.metadata.title,
            displayAuthor: item.media?.metadata.authorName,
            coverPath: item.media?.coverPath,
            duration: item.media?.duration,
            playMethod: 3,
            mediaPlayer: "ShelfPlayer",
            deviceInfo: .current,
            serverVersion: status.serverVersion,
            timeListening: timeListened,
            startTime: startTime,
            currentTime: currentTime,
            startedAt: started.timeIntervalSince1970 * 1000,
            updatedAt: updated.timeIntervalSince1970 * 1000)
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/session/local", method: "POST", body: session))
    }
}
