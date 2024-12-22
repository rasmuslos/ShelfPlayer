//
//  OfflineEpisode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    public final class OfflineEpisode {
        @Attribute(.unique)
        public let id: String
        public let libraryId: String
        
        public let name: String
        public let author: String?
        
        public let overview: String?
        
        public let addedAt: Date
        public let released: String?
        
        @Relationship
        public var podcast: OfflinePodcast
        
        public let index: Int
        public let duration: TimeInterval
        
        public init(id: String, libraryId: String, name: String, author: String?, overview: String?, addedAt: Date, released: String?, podcast: OfflinePodcast, index: Int, duration: TimeInterval) {
            self.id = id
            self.libraryId = libraryId
            self.name = name
            self.author = author
            self.overview = overview
            self.addedAt = addedAt
            self.released = released
            self.podcast = podcast
            self.index = index
            self.duration = duration
        }
    }
}
