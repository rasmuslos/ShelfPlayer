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
        let _ = try await request(ClientRequest<Empty>(path: "api/me/progress/\(itemID.pathComponent)", method: .patch, body: [
            "isFinished": finished,
        ]))
    }
}

public extension APIClient {
    func updateProgress(itemID: ItemIdentifier, currentTime: TimeInterval, duration: TimeInterval) async throws {
        let progress = currentTime / duration
        let _ = try await request(ClientRequest<Empty>(path: "api/me/progress/\(itemID.pathComponent)", method: .patch, body: [
            "duration": duration,
            "currentTime": currentTime,
            "progress": progress,
            "isFinished": progress >= 1 ? "true" : "false",
        ]))
    }
    
    func deleteProgress(progressID: String) async throws {
        let _ = try await request(ClientRequest<Empty>(path: "api/me/progress/\(progressID)", method: .delete))
    }
    
    func listeningSessions(with itemID: ItemIdentifier) async throws -> [SessionPayload] {
        try await request(ClientRequest<SessionsResponse>(path: "api/me/item/listening-sessions/\(itemID.pathComponent)", method: .get)).sessions
    }
}
