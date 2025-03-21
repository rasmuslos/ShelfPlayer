//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 05.04.24.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient {
    func startPlaybackSession(itemID: ItemIdentifier) async throws -> ([PlayableItem.AudioTrack], [Chapter], TimeInterval, String) {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        var path = "api/items"
        
        if let groupingID = itemID.groupingID {
            path.append("/\(groupingID)/play/\(itemID.primaryID)")
        } else {
            path.append("/\(itemID.primaryID)/play")
        }
        
        let response = try await response(for: ClientRequest<ItemPayload>(path: path, method: .post, body: [
            "deviceInfo": [
                "deviceId": ShelfPlayerKit.clientID,
                "clientName": "ShelfPlayer",
                "clientVersion": ShelfPlayerKit.clientVersion,
                "manufacturer": "Apple",
                "model": ShelfPlayerKit.model,
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
            throw APIClientError.invalidResponse
        }
        
        let startTime = response.startTime ?? 0
        let playbackSessionID = response.id
        
        return (tracks.map { .init(track: $0, base: host) }, chapters.map(Chapter.init), startTime, playbackSessionID)
    }
    
    func createListeningSession(itemID: ItemIdentifier, timeListened: TimeInterval, startTime: TimeInterval, currentTime: TimeInterval, started: Date, updated: Date) async throws {
        let (item, status, userID) = try await (item(itemID: itemID), status(), me().0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dayOfWeekFormatter = DateFormatter()
        dayOfWeekFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayOfWeekFormatter.dateFormat = "EEEE"
        
        let session = SessionPayload(
            id: UUID().uuidString,
            userId: userID,
            libraryId: item.libraryId,
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
            deviceInfo: .init(id: ShelfPlayerKit.clientID,
                              userId: userID,
                              deviceId: ShelfPlayerKit.clientID,
                              browserName: "ShelfPlayer",
                              browserVersion: ShelfPlayerKit.clientVersion,
                              osName: "iOS",
                              osVersion: await ShelfPlayerKit.osVersion,
                              deviceType: "iPhone",
                              manufacturer: "Apple",
                              model: ShelfPlayerKit.model,
                              clientName: "ShelfPlayer",
                              clientVersion: ShelfPlayerKit.clientVersion),
            date: dateFormatter.string(from: started),
            dayOfWeek: dayOfWeekFormatter.string(from: started),
            serverVersion: status.serverVersion,
            timeListening: timeListened,
            startTime: startTime,
            currentTime: currentTime,
            startedAt: Double(UInt64(started.timeIntervalSince1970 * 1000)),
            updatedAt: Double(UInt64(updated.timeIntervalSince1970 * 1000)))
        
        try await response(for: ClientRequest<Empty>(path: "api/session/local", method: .post, body: session))
    }
    
    func syncSession(sessionID: String, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/session/\(sessionID)/sync", method: .post, body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
    func closeSession(sessionID: String, currentTime: TimeInterval, duration: TimeInterval, timeListened: TimeInterval) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/session/\(sessionID)/close", method: .post, body: [
            "duration": duration,
            "currentTime": currentTime,
            "timeListened": timeListened,
        ]))
    }
}
