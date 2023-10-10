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
    func play(itemId: String, episodeId: String?) async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters, Double) {
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
        
        return (tracks, chapters, startTime)
    }
}
