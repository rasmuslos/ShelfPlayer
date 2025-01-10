//
//  PersistedAudiobook.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedAudiobook {
        #Index<PersistedAudiobook>([\._id], [\.name])
        #Unique<PersistedAudiobook>([\._id])
        
        private var _id: String
        
        private(set) var name: String
        private(set) var authors: [String]
        
        private(set) var overview: String?
        private(set) var genres: [String]
        
        private(set) var addedAt: Date
        private(set) var released: String?
        
        private(set) var size: Int64
        private(set) var duration: TimeInterval
        
        private(set) var subtitle: String?
        private(set) var narrators: [String]
        
        private(set) var series: [Audiobook.SeriesFragment]
        
        private(set) var explicit: Bool
        private(set) var abridged: Bool
        
        @Relationship(deleteRule: .deny, minimumModelCount: 1)
        private(set) var tracks: [PersistedAsset]
        
        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        private(set) var searchIndexEntry: PersistedSearchIndexEntry
        
        init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, genres: [String], addedAt: Date, released: String? = nil, size: Int64, duration: TimeInterval, subtitle: String? = nil, narrators: [String], series: [Audiobook.SeriesFragment], explicit: Bool, abridged: Bool, tracks: [PersistedAsset]) {
            _id = id.description
            
            self.name = name
            self.authors = authors
            
            self.overview = overview
            self.genres = genres
            
            self.addedAt = addedAt
            self.released = released
            
            self.size = size
            self.duration = duration
            
            self.subtitle = subtitle
            self.narrators = narrators
            
            self.series = series
            
            self.explicit = explicit
            self.abridged = abridged
            
            self.tracks = tracks
            
            searchIndexEntry = .init(itemID: id, primaryName: name, secondaryName: subtitle, authors: authors)
        }
        
        var id: ItemIdentifier {
            .init(_id)
        }
    }
}
