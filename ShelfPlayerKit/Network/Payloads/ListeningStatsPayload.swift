//
//  ListeningStatsPayload.swift
//  ShelfPlayerKit
//

import Foundation

public struct ListeningStatsPayload: Codable, Sendable {
    public let totalTime: Double
    public let items: [String: ItemStats]
    public let days: [String: Double]
    public let dayOfWeek: [String: Double]
    public let today: Double
    public let recentSessions: [SessionPayload]

    public struct ItemStats: Codable, Sendable {
        public let id: String
        public let timeListening: Double
        public let mediaMetadata: MediaMetadata
    }

    public struct MediaMetadata: Codable, Sendable {
        public let title: String?
        public let author: String?
        public let authorName: String?

        public var resolvedAuthor: String? {
            author ?? authorName
        }
    }
}
