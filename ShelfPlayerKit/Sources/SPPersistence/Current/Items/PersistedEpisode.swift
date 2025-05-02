//
//  PersistedEpisode.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.7.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedEpisode {
        #Index<PersistedEpisode>([\._id], [\.name])
        #Unique<PersistedEpisode>([\._id])
        
        private(set) var _id: String
        
        private(set) var name: String
        private(set) var authors: [String]
        
        private(set) var overview: String?
        
        private(set) var addedAt: Date
        private(set) var released: String?
        
        private(set) var size: Int64?
        private(set) var duration: TimeInterval
        
        private(set) var type: Episode.EpisodeType
        private(set) var index: Episode.EpisodeIndex
        
        @Relationship(deleteRule: .deny, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var podcast: PersistedPodcast
        
        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var searchIndexEntry: PersistedSearchIndexEntry
        
        init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, addedAt: Date, released: String? = nil, size: Int64?, duration: TimeInterval, podcast: PersistedPodcast, type: Episode.EpisodeType, index: Episode.EpisodeIndex) {
            _id = id.description
            
            self.name = name
            self.authors = authors
            
            self.overview = overview
            
            self.addedAt = addedAt
            self.released = released
            
            self.size = size
            self.duration = duration
            
            self.podcast = podcast
            
            self.type = type
            self.index = index
            
            searchIndexEntry = .init(itemID: id, primaryName: name, secondaryName: podcast.name, authors: authors)
        }
        
        var id: ItemIdentifier {
            .init(string: _id)
        }
    }
}

