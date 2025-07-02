//
//  ResolvedUpNextStrategy+Resolve.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.05.25.
//

import Foundation

public extension ResolvedUpNextStrategy {
    func resolve(cutoff itemID: ItemIdentifier?) async throws -> [PlayableItem] {
        switch self {
            case .series(let seriesID):
                let unfiltered = try await ABSClient[seriesID.connectionID].audiobooks(filtered: seriesID, sortOrder: nil, ascending: nil, limit: nil, page: nil).0
                var audiobooks = [Audiobook]()
                
                for audiobook in unfiltered {
                    guard await audiobook.isIncluded(in: Defaults[.audiobooksFilter]) else {
                        continue
                    }
                    
                    audiobooks.append(audiobook)
                }
                
                guard let itemID else {
                    return audiobooks
                }
                
                guard let index = audiobooks.firstIndex(where: { $0.id == itemID }) else {
                    throw ResolveError.missingCutoff
                }
                
                return Array(audiobooks[(index + 1)...])
            case .podcast(let podcastID):
                let (_, episodes) = try await podcastID.resolvedComplex
                
                return await Podcast.filterSort(episodes, podcastID: podcastID).filter { $0.id != itemID }
            case .listenNow:
                return await ShelfPlayerKit.listenNowItems.filter { $0.id != itemID }
            default:
                throw ResolveError.invalidItemType
        }
        
    }
}

private enum ResolveError: Error {
    case missingCutoff
    case invalidItemType
}
