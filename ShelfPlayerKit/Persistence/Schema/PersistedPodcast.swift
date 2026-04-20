//
//  PersistedPodcast.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedPodcast {
        #Index<PersistedPodcast>([\._id])
        #Unique<PersistedPodcast>([\._id])

        public private(set) var _id: String

        public private(set) var name: String
        public private(set) var authors: [String]

        public private(set) var overview: String?
        public private(set) var genres: [String]

        public private(set) var addedAt: Date
        public private(set) var released: String?

        public private(set) var explicit: Bool
        public private(set) var publishingType: Podcast.PodcastType?

        public private(set) var totalEpisodeCount: Int

        @Relationship(deleteRule: .cascade, inverse: \PersistedEpisode.podcast)
        public var episodes: [PersistedEpisode]

        public init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, genres: [String], addedAt: Date, released: String?, explicit: Bool, publishingType: Podcast.PodcastType?, totalEpisodeCount: Int, episodes: [PersistedEpisode]) {
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

        public var id: ItemIdentifier {
            .init(string: _id)
        }
    }
}
