//
//  Progress.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import RFNetwork


public extension APIClient {
    func finished(_ finished: Bool, itemID: ItemIdentifier) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/me/progress/\(itemID.pathComponent)", method: .patch, body: [
            "isFinished": finished,
        ]))
    }
}

public extension APIClient {
    func batchUpdate(progress: [ProgressEntity]) async throws {
        try await response(for: ClientRequest<Empty>(path: "api/me/progress/batch/update", method: .patch, body: progress.map {
            let itemID: String
            let episodeID: String?
            
            if let groupingID = $0.groupingID {
                itemID = groupingID
                episodeID = $0.primaryID
            } else {
                itemID = $0.primaryID
                episodeID = nil
            }
            
            return ProgressPayload(id: $0.id,
                                   libraryItemId: itemID,
                                   episodeId: episodeID,
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
        try await response(for: ClientRequest<Empty>(path: "api/me/progress/\(progressID)", method: .delete))
    }
    
    func listeningSessions(page: Int, pageSize: Int) async throws -> [SessionPayload] {
        let response = try await response(for: ClientRequest<SessionsResponse>(path: "api/me/listening-sessions", method: .get, query: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "itemsPerPage", value: "\(pageSize)"),
        ]))
        
        return response.sessions
    }
    func listeningSessions(from itemID: ItemIdentifier, page: Int, pageSize: Int) async throws -> [SessionPayload] {
        let response = try await response(for: ClientRequest<SessionsResponse>(path: "api/me/item/listening-sessions/\(itemID.pathComponent)", method: .get, query: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "itemsPerPage", value: "\(pageSize)"),
        ]))
        
        return response.sessions
    }
}
