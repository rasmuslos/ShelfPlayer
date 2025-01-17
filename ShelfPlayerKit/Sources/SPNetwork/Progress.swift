//
//  Progress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import RFNetwork
import SPFoundation

public extension APIClient {
    func finished(_ finished: Bool, itemID: ItemIdentifier) async throws {
        try await request(ClientRequest<Empty>(path: "api/me/progress/\(itemID.pathComponent)", method: .patch, body: [
            "isFinished": finished,
        ]))
    }
}

public extension APIClient {
    func batchUpdate(progress: [ProgressEntity]) async throws {
        try await request(ClientRequest<Empty>(path: "me/progress/batch/update", method: .post, body: progress.map {
            ProgressPayload(id: $0.id,
                            libraryItemId: $0.itemID.apiItemID,
                            episodeId: $0.itemID.apiEpisodeID,
                            duration: $0.duration ?? 0,
                            progress: $0.progress,
                            currentTime: $0.currentTime,
                            isFinished: $0.isFinished,
                            hideFromContinueListening: false,
                            lastUpdate: Int64($0.lastUpdate.timeIntervalSince1970) * 1000,
                            startedAt: Int64($0.startedAt?.timeIntervalSince1970 ?? 0) * 1000,
                            finishedAt: Int64($0.finishedAt?.timeIntervalSince1970 ?? 0) * 1000)
        }))
    }
    
    func delete(progressID: String) async throws {
        try await request(ClientRequest<Empty>(path: "api/me/progress/\(progressID)", method: .delete))
    }
    
    func listeningSessions(with itemID: ItemIdentifier) async throws -> [SessionPayload] {
        try await request(ClientRequest<SessionsResponse>(path: "api/me/item/listening-sessions/\(itemID.pathComponent)", method: .get)).sessions
    }
}
