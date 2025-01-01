//
//  OfflineEpisode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

@available(*, deprecated, renamed: "SchemaV2", message: "Outdated schema")
extension SchemaV1 {
    @Model
    final class OfflineEpisode {
        @Attribute(.unique)
        var id: String
        var libraryId: String
        
        var name: String
        var author: String?
        
        var overview: String?
        
        var addedAt: Date
        var released: String?
        
        @Relationship
        var podcast: OfflinePodcast
        
        var index: Int
        var duration: TimeInterval
        
        init(id: String, libraryId: String, name: String, author: String?, overview: String?, addedAt: Date, released: String?, podcast: OfflinePodcast, index: Int, duration: TimeInterval) {
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
