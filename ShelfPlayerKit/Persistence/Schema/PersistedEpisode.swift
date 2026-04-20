//
//  PersistedEpisode.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedEpisode {
        #Index<PersistedEpisode>([\._id], [\.name])
        #Unique<PersistedEpisode>([\._id])

        public private(set) var _id: String

        public private(set) var name: String
        public private(set) var authors: [String]

        public private(set) var overview: String?

        public private(set) var addedAt: Date
        public private(set) var released: String?

        public private(set) var size: Int64?
        public private(set) var duration: TimeInterval

        public private(set) var type: Episode.EpisodeType
        public private(set) var index: Episode.EpisodeIndex

        @Relationship(deleteRule: .deny, minimumModelCount: 1, maximumModelCount: 1)
        public private(set) var podcast: PersistedPodcast

        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        public private(set) var searchIndexEntry: PersistedSearchIndexEntry

        public init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, addedAt: Date, released: String? = nil, size: Int64?, duration: TimeInterval, podcast: PersistedPodcast, type: Episode.EpisodeType, index: Episode.EpisodeIndex) {
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

        public var id: ItemIdentifier {
            .init(string: _id)
        }
    }
}
