//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation

private typealias ConvenienceDownloadConfiguration = PersistenceManager.ConvenienceDownloadSubsystem.ConvenienceDownloadConfiguration

extension PersistenceManager {
    public struct ConvenienceDownloadSubsystem {
    }
}

public extension PersistenceManager.ConvenienceDownloadSubsystem {
    enum ConvenienceDownloadConfiguration: Codable, Sendable, Identifiable {
        case listenNow
        case collection(ItemIdentifier, CollectionRetrieval)
        
        public var id: String {
            switch self {
            case .listenNow:
                "listenNow"
            case .collection(let itemID, _):
                "collection-\(itemID)"
            }
        }
        
        var key: PersistenceManager.KeyValueSubsystem.Key<Self> {
            .init(identifier: "convinienceDownloadConfiguration-\(id)", cluster: "convenienceDownloadConfigurations", isCachePurgeable: false)
        }
        var items: [PlayableItem] {
            get async throws {
                switch self {
                case .collection(let itemID, let reteival):
                    let strategy: ResolvedUpNextStrategy
                    
                    switch itemID.type {
                    case .series:
                        strategy = .series(itemID)
                    case .podcast:
                        strategy = .podcast(itemID)
                    default:
                        throw ConvenienceDownloadError.invalidItemType
                    }
                    
                    let items = try await strategy.resolve(cutoff: nil)
                    let result: [PlayableItem]
                    
                    switch reteival {
                    case .all:
                        result = items
                    case .amount(let count):
                        result = Array(items[0..<count])
                    case .cutoff(let seconds):
                        result = items.filter {
                            if let episode = $0 as? Episode, let releaseDate = episode.releaseDate {
                                releaseDate.distance(to: Date()) < seconds
                            } else {
                                false
                            }
                        }
                    }
                    
                    return result
                case .listenNow:
                    return await ShelfPlayerKit.listenNowItems
                }
            }
        }
    }
    enum CollectionRetrieval: Codable, Sendable {
        case all
        case amount(Int)
        case cutoff(TimeInterval)
    }
    
    private enum ConvenienceDownloadError: Error {
        case invalidItemType
    }
}

