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
        public subscript(id: ItemIdentifier) -> PodcastAutoDownloadConfiguration {
            get async {
                if let configuration = await PersistenceManager.shared.keyValue[.podcastAutoDownloadConfiguration(id)] {
                    return configuration
                }
                
                let configuration = PodcastAutoDownloadConfiguration(itemID: id, enabled: false, amount: 5, enableNotifications: false)
                try? await PersistenceManager.shared.keyValue.set(.podcastAutoDownloadConfiguration(id), configuration)
                
                return configuration
            }
        }
        
        public func set(_ id: ItemIdentifier, _ configuration: PodcastAutoDownloadConfiguration) async throws {
            try await PersistenceManager.shared.keyValue.set(.podcastAutoDownloadConfiguration(id), configuration)
        }
        
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

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func podcastAutoDownloadConfiguration(_ itemID: ItemIdentifier) -> Key<PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration> {
        .init("podcastAutoDownloadConfiguration-\(itemID.groupingID ?? itemID.primaryID)")
    }
}
