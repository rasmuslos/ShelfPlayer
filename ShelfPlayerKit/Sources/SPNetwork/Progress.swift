//
//  Progress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import SPFoundation

public extension AudiobookshelfClient {
    func finished(_ finished: Bool, itemID: ItemIdentifier) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemID.pathComponent)", method: "PATCH", body: [
            "isFinished": finished,
        ]))
    }
}

public extension AudiobookshelfClient {
    func updateProgress(itemID: ItemIdentifier, currentTime: TimeInterval, duration: TimeInterval) async throws {
        let progress = currentTime / duration
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemID.pathComponent)", method: "PATCH", body: [
            "duration": duration,
            "currentTime": currentTime,
            "progress": progress,
            "isFinished": progress >= 1 ? "true" : "false",
        ]))
    }
    
    func deleteProgress(itemID: ItemIdentifier) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "api/me/progress/\(itemID.pathComponent)", method: "DELETE"))
    }
    
    func listeningSessions(with itemID: ItemIdentifier) async throws -> [SessionPayload] {
        try await request(ClientRequest<SessionsResponse>(path: "api/me/item/listening-sessions/\(itemID.pathComponent)", method: "GET")).sessions
    }
    
    func createListeningSession(itemId: String, episodeId: String?, id: String, timeListened: TimeInterval, startTime: TimeInterval, currentTime: TimeInterval, started: Date, updated: Date) async throws {
        let (item, status, userId): (ItemPayload, StatusResponse, String) = try await (item(itemId: itemId), status(), me().0)
        
        let session = SessionPayload(
            id: id,
            userId: userId,
            libraryID: item.libraryId,
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
