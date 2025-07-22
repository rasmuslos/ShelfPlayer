//
//  ResolvedUpNextStrategy+Resolve.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.05.25.
//

import Foundation

extension ResolvedUpNextStrategy {
    public func resolve(cutoff itemID: ItemIdentifier?) async throws -> [PlayableItem] {
        switch self {
            case .series(let seriesID):
                return try await prepare(try await ABSClient[seriesID.connectionID].audiobooks(filtered: seriesID, sortOrder: nil, ascending: nil, limit: nil, page: nil).0, itemID)
            case .podcast(let podcastID):
                let (_, episodes) = try await podcastID.resolvedComplex
                
                return await Podcast.filterSort(episodes, podcastID: podcastID).filter { $0.id != itemID }
                
            case .collection(let collectionID):
                guard let collection = try await collectionID.resolved as? ItemCollection else {
                    throw ResolveError.invalidItemType
                }
                
                if let audiobooks = collection.audiobooks {
                    return try await prepare(audiobooks, itemID)
                } else if let episodes = collection.episodes {
                    return try await prepare(episodes, itemID)
                } else {
                    throw ResolveError.invalidItemType
                }
                
            case .listenNow:
                return await ShelfPlayerKit.listenNowItems.filter { $0.id != itemID }
                
            default:
                throw ResolveError.invalidItemType
        }
        
    }
    
    private func prepare(_ unfiltered: [PlayableItem], _ itemID: ItemIdentifier?) async throws -> [PlayableItem] {
        var result = [PlayableItem]()
        
        for item in unfiltered {
            guard await item.isIncluded(in: .notFinished) else {
                continue
            }
            
            result.append(item)
        }
        
        guard let itemID else {
            return result
        }
        
        guard let index = result.firstIndex(where: { $0.id == itemID }) else {
            throw ResolveError.missingCutoff
        }
        
        return Array(result[(index + 1)...])
    }
}

private enum ResolveError: Error {
    case missingCutoff
    case invalidItemType
}
