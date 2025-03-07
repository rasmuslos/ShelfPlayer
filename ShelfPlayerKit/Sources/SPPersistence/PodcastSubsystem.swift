//
//  PodcastSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.12.24.
//

import Foundation
import SwiftData
import RFNotifications
import SPFoundation

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
    func configuration(for itemID: ItemIdentifier) async -> PodcastAutoDownloadConfiguration {
        if let configuration = await PersistenceManager.shared.keyValue[.podcastAutoDownloadConfiguration(for: itemID)] {
            return configuration
        }
        
        let configuration = PodcastAutoDownloadConfiguration(itemID: itemID, enabled: false, amount: 5, enableNotifications: false)
        try? await PersistenceManager.shared.keyValue.set(.podcastAutoDownloadConfiguration(for: itemID), configuration)
        
        return configuration
    }
    func set(configuration: PodcastAutoDownloadConfiguration, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.podcastAutoDownloadConfiguration(for: itemID), configuration)
    }
    
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
    static func podcastAutoDownloadConfiguration(for itemID: ItemIdentifier) -> Key<PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration> {
        .init("podcastAutoDownloadConfiguration-\(itemID.groupingID ?? itemID.primaryID)")
    }
    static func podcastPlaybackRate(for itemID: ItemIdentifier) -> Key<Percentage> {
        .init("podcastPlaybackRate-\(itemID.groupingID ?? itemID.primaryID)")
    }
    static func podcastAllowNextUpQueueGeneration(for itemID: ItemIdentifier) -> Key<Bool> {
        .init("podcastAllowNextUpQueueGeneration-\(itemID.groupingID ?? itemID.primaryID)")
    }
}
