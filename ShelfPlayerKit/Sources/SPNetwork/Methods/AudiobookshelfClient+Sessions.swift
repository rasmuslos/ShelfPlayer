//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.04.24.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func finished(_ finished: Bool, itemId: String, episodeId: String?) async throws {
        var url = "api/me/progress/\(itemId)"
        
        if let episodeId {
            url.append("/\(episodeId)")
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: url, method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
    func deleteProgress(itemId: String, episodeId: String?) async throws {
        var url = "api/me/progress/\(itemId)"
        
        if let episodeId {
            url.append("/\(episodeId)")
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: url, method: "DELETE"))
    }
}

public extension AudiobookshelfClient {
    func startPlaybackSession(itemId: String, episodeId: String?) async throws -> ([PlayableItem.AudioTrack], [PlayableItem.Chapter], TimeInterval, String) {
        var url = "api/items/\(itemId)/play"
        
        if let episodeId {
            url.append("/\(episodeId)")
        }
        
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: url, method: "POST", body: [
            "deviceInfo": [
                "clientName": "ShelfPlayer",
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
        
        guard let tracks = response.audioTracks, let chapters = response.chapters else {
            throw ClientError.invalidResponse
        }
        
        let startTime = response.startTime ?? 0
        let playbackSessionId = response.id
        
        return (tracks.map(PlayableItem.AudioTrack.init), chapters.map(PlayableItem.Chapter.init), startTime, playbackSessionId)
    }
    
    func reportUpdate(playbackSessionId: String, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/session/\(playbackSessionId)/sync", method: "POST", body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
    func reportClose(playbackSessionId: String, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/session/\(playbackSessionId)/close", method: "POST", body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
}

public extension AudiobookshelfClient {
    func updateProgress(itemId: String, episodeId: String?, currentTime: TimeInterval, duration: TimeInterval) async throws {
        var url = "api/me/progress/\(itemId)"
        
        if let episodeId {
            url.append("/\(episodeId)")
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: url, method: "PATCH", body: [
            "duration": duration,
            "currentTime": currentTime,
            "progress": currentTime / duration,
            "isFinished": duration - currentTime <= 10,
        ]))
    }
    
    func listeningSessions(for itemID: String, episodeID: String?) async throws -> [ListeningSession] {
        var path = "api/me/item/listening-sessions/\(itemID)"
        
        if let episodeID {
            path.append("/\(episodeID)")
        }
        
        let response = try await request(ClientRequest<ListeningSessionsResponse>(path: path, method: "GET"))
        return response.sessions
    }
    
    func createListeningSession(itemId: String, episodeId: String?, id: String, timeListened: TimeInterval, startTime: TimeInterval, currentTime: TimeInterval, started: Date, updated: Date) async throws {
        let (item, status, userId): (AudiobookshelfItem, StatusResponse, String) = try await (item(itemId: itemId), status(), me().0)
        
        let session = ListeningSession(
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
