//
//  Podcast+Sort.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 06.03.25.
//

import Foundation


public extension Podcast {
    static func filterSort(_ episodes: [Episode], podcastID: ItemIdentifier) async -> [Episode] {
        let configuration = await PersistenceManager.shared.item.podcastFilterSortConfiguration(for: podcastID)
        return await filterSort(episodes, filter: configuration.filter, seasonFilter: configuration.seasonFilter, restrictToPersisted: configuration.restrictToPersisted, search: nil, sortOrder: configuration.sortOrder, ascending: configuration.ascending)
    }
    static func filterSort(_ episodes: [Episode], filter: ItemFilter, seasonFilter: String?, restrictToPersisted: Bool, search: String?, sortOrder: EpisodeSortOrder, ascending: Bool) async -> [Episode] {
        var episodes = episodes
        
        if let seasonFilter {
            episodes = episodes.filter { $0.index.season == seasonFilter }
        }
        
        if restrictToPersisted {
            var included = [Episode]()
            
            for episode in episodes {
                guard await PersistenceManager.shared.download.status(of: episode.id) != .none else {
                    continue
                }
                
                included.append(episode)
            }
            
            episodes = included
        }
        
        // MARK: Filter
        
        if filter != .all {
            var included = [Episode]()
            
            for episode in episodes {
                if await episode.isIncluded(in: filter) {
                    included.append(episode)
                }
            }
            
            episodes = included
        }
        
        // MARK: Search
        
        if let search = search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            episodes = episodes.filter { $0.sortName.localizedStandardContains(search) || $0.descriptionText?.localizedStandardContains(search) == true }
        }
        
        // MARK: Sort
        
        episodes.sort { $0.compare(other: $1, sortOrder: sortOrder, ascending: ascending) }
        
        if !ascending {
            episodes.reverse()
        }
        
        return episodes
    }
}
