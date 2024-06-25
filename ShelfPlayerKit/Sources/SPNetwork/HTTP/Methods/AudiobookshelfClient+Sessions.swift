//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.04.24.
//

import Foundation

public extension AudiobookshelfClient {
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
        let (item, status, userId): (AudiobookshelfItem, StatusResponse, String) = try await (getItem(itemId: itemId), status(), userId())
        
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
    
    func deleteSession(sessionId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/sessions/\(sessionId)", method: "DELETE"))
    }
}
