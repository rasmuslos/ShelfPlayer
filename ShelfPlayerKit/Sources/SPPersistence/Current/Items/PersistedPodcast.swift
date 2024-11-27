//
//  PersistedPodcast.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedPodcast {
        @Attribute(.unique)
        private(set) var id: ItemIdentifier
        
        private(set) var name: String
        private(set) var authors: [String]
        
        private(set) var overview: String?
        private(set) var genres: [String]
        
        private(set) var addedAt: Date
        private(set) var released: String?
        
        private(set) var explicit: Bool
        private(set) var episodeCount: Int
        
        private(set) var publishingType: PodcastType?
        
        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var searchIndexEntry: PersistedSearchIndexEntry
    }
}
