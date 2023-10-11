//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import Foundation

// MARK: finished

extension AudiobookshelfClient {
    func setFinished(itemId: String, episodeId: String?, finished: Bool) async throws {
        let episodeId = episodeId != nil ? "/\(episodeId!)" : ""
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(episodeId)", method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
}

// MARK: play

extension AudiobookshelfClient {
    func play(itemId: String, episodeId: String?) async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters, Double, String) {
        // this is actually not an AudiobookshelfItem... to bad
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(itemId)/play\(episodeId != nil ? "/\(episodeId!)" : "")", method: "POST", body: [
            "deviceInfo": [
                "clientName": "Audiobooks iOS",
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
}

// MARK: Progress

extension AudiobookshelfClient {
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
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemId)\(episodeId != nil ? "/\(episodeId!)" : "")", method: "PATCH", body: [
            "duration": duration,
            "currentTime": currentTime,
            "progress": currentTime / duration,
            "isFinished": duration - currentTime <= 10,
        ]))
    }
}
