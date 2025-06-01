//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import Defaults


private typealias ConvenienceDownloadConfiguration = PersistenceManager.ConvenienceDownloadSubsystem.ConvenienceDownloadConfiguration

extension PersistenceManager {
    public struct ConvenienceDownloadSubsystem {
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    func synchronize() {
        
    }
    
    func configurations() async throws -> [ConvenienceDownloadConfiguration] {
        await PersistenceManager.shared.keyValue.entities(cluster: "convenienceDownloadConfigurations", type: ConvenienceDownloadConfiguration.self).map(\.value)
    }
    func updateConfiguration(_ configuration: ConvenienceDownloadConfiguration?, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.convenienceDownloadConfiguration(for: itemID), configuration)
    }
    
    enum ConvenienceDownloadConfiguration: Codable, Sendable {
        case listenNow
        case collection(ItemIdentifier, CollectionRetrieval)
    }
    enum CollectionRetrieval: Codable, Sendable {
        case amount(Int)
        case cutoffDate(Date)
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func convenienceDownloadConfiguration(for itemID: ItemIdentifier) -> Key<ConvenienceDownloadConfiguration> {
        Key(identifier: "convenienceDownloadConfiguration-\(itemID)", cluster: "convenienceDownloadConfigurations", isCachePurgeable: false)
    }
}
