//
//  API+Stats.swift
//  ShelfPlayerKit
//

import Foundation

public extension APIClient {
    func listeningStats() async throws -> ListeningStatsPayload {
        try await response(APIRequest<ListeningStatsPayload>(path: "api/me/listening-stats", method: .get, ttl: 60))
    }
}
