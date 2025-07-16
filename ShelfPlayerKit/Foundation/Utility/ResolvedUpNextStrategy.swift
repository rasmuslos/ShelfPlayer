//
//  ResolvedUpNextStrategy.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.05.25.
//

import Foundation

public enum ResolvedUpNextStrategy: Sendable {
    case listenNow
    
    case series(ItemIdentifier)
    case podcast(ItemIdentifier)
    
    case collection(ItemIdentifier)
    
    case none
    
    public static func nextGroupingItem(_ itemID: ItemIdentifier) async throws -> ItemIdentifier {
        switch itemID.type {
            case .series:
                guard let audiobook = try await ResolvedUpNextStrategy.series(itemID).resolve(cutoff: nil).first else {
                    throw ResolverError.missing
                }
                
                return audiobook.id
            case .podcast:
                guard let episode = try await ResolvedUpNextStrategy.podcast(itemID).resolve(cutoff: nil).first else {
                    throw ResolverError.missing
                }
                
                return episode.id
            case .collection, .playlist:
                guard let item = try await ResolvedUpNextStrategy.collection(itemID).resolve(cutoff: nil).first else {
                    throw ResolverError.missing
                }
                
                return item.id
            default:
                throw IntentError.invalidItemType
        }
    }
}

private enum ResolverError: Error {
    case missing
}
