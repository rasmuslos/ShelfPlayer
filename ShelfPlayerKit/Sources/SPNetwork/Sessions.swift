//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.04.24.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func startPlaybackSession(itemID: ItemIdentifier) async throws -> ([PlayableItem.AudioTrack], [Chapter], TimeInterval, String) {
        let response = try await request(ClientRequest<ItemPayload>(path: "api/items/\(itemID.pathComponent)/play", method: "POST", body: [
            "deviceInfo": [
                "deviceId": clientID,
                "clientName": "ShelfPlayer",
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
        let playbackSessionID = response.id
        
        return (tracks.map(PlayableItem.AudioTrack.init), chapters.map(Chapter.init), startTime, playbackSessionID)
    }
    
    func createListeningSession(itemID: ItemIdentifier, id: UUID, timeListened: TimeInterval, startTime: TimeInterval, currentTime: TimeInterval, started: Date, updated: Date) async throws {
        let (item, status, userId): (ItemPayload, StatusResponse, String) = try await (item(itemID: itemID), status(), me().0)
        
        let session = SessionPayload(
            id: id.uuidString,
            userId: userId,
            libraryID: item.libraryId,
            libraryItemId: itemID.apiItemID,
            episodeId: itemID.apiEpisodeID,
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
