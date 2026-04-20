//
//  PersistedAudiobook.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedAudiobook {
        #Index<PersistedAudiobook>([\._id], [\.name])
        #Unique<PersistedAudiobook>([\._id])

        public private(set) var _id: String

        public private(set) var name: String
        public private(set) var authors: [String]

        public private(set) var overview: String?
        public private(set) var genres: [String]

        public private(set) var addedAt: Date
        public private(set) var released: String?

        public private(set) var size: Int64?
        public private(set) var duration: TimeInterval

        public private(set) var subtitle: String?
        public private(set) var narrators: [String]

        public private(set) var series: [Audiobook.SeriesFragment]

        public private(set) var explicit: Bool
        public private(set) var abridged: Bool

        @Relationship(deleteRule: .cascade, minimumModelCount: 1, maximumModelCount: 1)
        public private(set) var searchIndexEntry: PersistedSearchIndexEntry

        public init(id: ItemIdentifier, name: String, authors: [String], overview: String? = nil, genres: [String], addedAt: Date, released: String? = nil, size: Int64?, duration: TimeInterval, subtitle: String? = nil, narrators: [String], series: [Audiobook.SeriesFragment], explicit: Bool, abridged: Bool) {
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

            searchIndexEntry = .init(itemID: id, primaryName: name, secondaryName: subtitle, authors: authors)
        }

        public var id: ItemIdentifier {
            .init(string: _id)
        }
    }
}
