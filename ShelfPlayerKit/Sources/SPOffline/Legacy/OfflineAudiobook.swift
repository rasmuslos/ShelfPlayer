//
//  OfflineAudiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    public final class OfflineAudiobook {
        @Attribute(.unique)
        public let id: String
        public let libraryId: String
        
        public let name: String
        public let author: String?
        
        public let overview: String?
        
        public let genres: [String]
        
        public let addedAt: Date
        public let released: String?
        
        public let size: Int64
        
        public let narrator: String?
        public let seriesName: String?
        
        public let duration: TimeInterval
        
        public let explicit: Bool
        public let abridged: Bool
        
        public init(id: String, libraryId: String, name: String, author: String?, overview: String?, genres: [String], addedAt: Date, released: String?, size: Int64, narrator: String?, seriesName: String?, duration: TimeInterval, explicit: Bool, abridged: Bool) {
            self.id = id
            self.libraryId = libraryId
            self.name = name
            self.author = author
            self.overview = overview
            self.genres = genres
            self.addedAt = addedAt
            self.released = released
            self.size = size
            self.narrator = narrator
            self.seriesName = seriesName
            self.duration = duration
            self.explicit = explicit
            self.abridged = abridged
        }
    }
}
