//
//  PersistedPodcast.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.11.24.
//

import Foundation
import SwiftData


extension SchemaV2 {
    @Model
    final class PersistedPodcast {
        #Index<PersistedPodcast>([\._id])
        #Unique<PersistedPodcast>([\._id])
        
        private(set) var _id: String
        
        private(set) var name: String
        private(set) var authors: [String]
        
        private(set) var overview: String?
        private(set) var genres: [String]
        
        private(set) var addedAt: Date
        private(set) var released: String?
        
        private(set) var explicit: Bool
        private(set) var publishingType: Podcast.PodcastType?
        
        private(set) var totalEpisodeCount: Int
        
        @Relationship(deleteRule: .cascade, inverse: \PersistedEpisode.podcast)
        var episodes: [PersistedEpisode]
        
        init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, genres: [String], addedAt: Date, released: String?, explicit: Bool, publishingType: Podcast.PodcastType?, totalEpisodeCount: Int, episodes: [PersistedEpisode]) {
            _id = id.description
            self.name = name
            self.authors = authors
            self.overview = overview
            self.genres = genres
            self.addedAt = addedAt
            self.released = released
            self.explicit = explicit
            self.publishingType = publishingType
            self.totalEpisodeCount = totalEpisodeCount
            self.episodes = episodes
        }
        
        var id: ItemIdentifier {
            .init(string: _id)
        }
    }
}
