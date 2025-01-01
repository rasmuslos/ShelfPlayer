//
//  OfflinePodcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    final class OfflinePodcast {
        @Attribute(.unique)
        var id: String
        var libraryId: String
        
        var name: String
        var author: String?
        
        var overview: String?
        var genres: [String]
        
        var addedAt: Date
        var released: String?
        
        var explicit: Bool
        var episodeCount: Int
        
        init(id: String, libraryId: String, name: String, author: String?, overview: String?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int) {
            self.id = id
            self.libraryId = libraryId
            self.name = name
            self.author = author
            self.overview = overview
            self.genres = genres
            self.addedAt = addedAt
            self.released = released
            self.explicit = explicit
            self.episodeCount = episodeCount
        }
    }
}
