//
//  Defaults+Keys.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 29.10.24.
//

import Foundation
import Defaults

public extension Defaults.Keys {
    static let skipForwardsInterval = Key<Int>("skipForwardsInterval", default: 30)
    static let skipBackwardsInterval = Key<Int>("skipBackwardsInterval", default: 30)
    
    static func episodesFilter(podcastId: String) -> Defaults.Key<ItemFilter> {
        .init("episodesFilter-\(podcastId)", default: .unfinished)
    }
    
    static func episodesSortOrder(podcastId: String) -> Defaults.Key<EpisodeSortOrder> {
        .init("episodesSort-\(podcastId)", default: .released)
    }
    static func episodesAscending(podcastId: String) -> Defaults.Key<Bool> {
        .init("episodesFilterAscending-\(podcastId)", default: false)
    }
}
