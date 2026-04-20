//
//  PersistedPodcastFilterSort.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedPodcastFilterSort {
        #Index<PersistedPodcastFilterSort>([\.podcastID])
        #Unique<PersistedPodcastFilterSort>([\.podcastID])

        public private(set) var podcastID: String
        public var sortOrder: Int
        public var ascending: Bool
        public var filter: Int
        public var restrictToPersisted: Bool
        public var seasonFilter: String?

        public init(podcastID: String, sortOrder: Int, ascending: Bool, filter: Int, restrictToPersisted: Bool, seasonFilter: String? = nil) {
            self.podcastID = podcastID
            self.sortOrder = sortOrder
            self.ascending = ascending
            self.filter = filter
            self.restrictToPersisted = restrictToPersisted
            self.seasonFilter = seasonFilter
        }
    }
}
