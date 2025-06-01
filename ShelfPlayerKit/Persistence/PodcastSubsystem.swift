//
//  PodcastSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.12.24.
//

import Foundation
import SwiftData
import RFNotifications


extension PersistenceManager {
    public struct PodcastSubsystem: Sendable {
        public struct PodcastAutoDownloadConfiguration: Codable, Sendable {
            public let itemID: ItemIdentifier
            public let enabled: Bool
            public let amount: Int
            public let enableNotifications: Bool
            
            public init(itemID: ItemIdentifier, enabled: Bool, amount: Int, enableNotifications: Bool) {
                self.itemID = itemID
                self.enabled = enabled
                self.amount = amount
                self.enableNotifications = enableNotifications
            }
        }
    }
}

public extension PersistenceManager.PodcastSubsystem {
    func playbackRate(for itemID: ItemIdentifier) async -> Percentage? {
        await PersistenceManager.shared.keyValue[.podcastPlaybackRate(for: itemID)]
    }
    func setPlaybackRate(_ rate: Percentage?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.podcastPlaybackRate(for: itemID), rate)
    }
    
    func allowNextUpQueueGeneration(for itemID: ItemIdentifier) async -> Bool? {
        await PersistenceManager.shared.keyValue[.podcastAllowNextUpQueueGeneration(for: itemID)]
    }
    func setAllowNextUpQueueGeneration(_ allow: Bool?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.podcastAllowNextUpQueueGeneration(for: itemID), allow)
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func podcastPlaybackRate(for itemID: ItemIdentifier) -> Key<Percentage> {
        Key(identifier: "podcastPlaybackRate-\(itemID.groupingID ?? itemID.primaryID)", cluster: "podcastPlaybackRate", isCachePurgeable: false)
    }
    static func podcastAllowNextUpQueueGeneration(for itemID: ItemIdentifier) -> Key<Bool> {
        .Key(identifier: "podcastAllowNextUpQueueGeneration-\(itemID.groupingID ?? itemID.primaryID)", cluster: "podcastAllowNextUpQueueGeneration", isCachePurgeable: false)
    }
}
