//
//  OfflineAudiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    final class OfflineAudiobook {
        @Attribute(.unique)
        var id: String
        var libraryId: String
        
        var name: String
        var author: String?
        
        var overview: String?
        
        var genres: [String]
        
        var addedAt: Date
        var released: String?
        
        var size: Int64
        
        var narrator: String?
        var seriesName: String?
        
        var duration: TimeInterval
        
        var explicit: Bool
        var abridged: Bool
        
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
