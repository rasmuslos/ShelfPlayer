//
//  PlayableItem+Sort.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 01.02.25.
//

import Foundation


public extension Episode {
    func compare(other episode: Episode, sortOrder: EpisodeSortOrder, ascending: Bool) -> Bool {
        switch sortOrder {
        case .name:
            return name.localizedStandardCompare(episode.name) == .orderedAscending
        case .index:
            return index < episode.index
        case .released:
            guard let lhsReleaseDate = releaseDate else { return false }
            guard let rhsReleaseDate = episode.releaseDate else { return true }
            
            return lhsReleaseDate < rhsReleaseDate
        case .duration:
            return duration < episode.duration
        }
    }
}
