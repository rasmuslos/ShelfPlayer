//
//  OfflinePodcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

@Model
class OfflinePodcast {
    let id: String
    let libraryId: String
    
    let name: String
    let author: String?
    
    let overview: String?
    let genres: [String]
    
    let addedAt: Date
    let released: String?

    let explicit: Bool
    let episodeCount: Int
    
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
