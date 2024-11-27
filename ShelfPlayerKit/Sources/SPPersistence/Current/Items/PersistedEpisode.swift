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
        @Attribute(.unique)
        private(set) var id: ItemIdentifier
        
        private(set) var name: String
        private(set) var authors: [String]
        
        private(set) var overview: String?
        
        private(set) var addedAt: Date
        private(set) var released: String?
        
        private(set) var size: Int64
        private(set) var duration: TimeInterval
        
        private(set) var index: Episode.EpisodeIndex
        
        @Relationship(deleteRule: .deny, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var podcast: PersistedPodcast
        
        @Relationship(deleteRule: .deny, minimumModelCount: 1)
        private(set) var tracks: [PersistedAudioTrack]
        
        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var searchIndexEntry: PersistedSearchIndexEntry
        
        init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, addedAt: Date, released: String? = nil, size: Int64, duration: TimeInterval, podcast: PersistedPodcast, index: Episode.EpisodeIndex, tracks: [PersistedAudioTrack]) {
            self.id = id
            
            self.name = name
            self.authors = authors
            
            self.overview = overview
            
            self.addedAt = addedAt
            self.released = released
            
            self.size = size
            self.duration = duration
            
            self.podcast = podcast
            self.index = index
            
            self.tracks = tracks
            
            searchIndexEntry = .init(itemID: id, primaryName: name, secondaryName: podcast.name, author: authors)
        }
    }
}

