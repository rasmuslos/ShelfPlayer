//
//  OfflineAudiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SwiftData

@Model
class OfflineAudiobook {
    @Attribute(.unique)
    let id: String
    let libraryId: String
    
    let name: String
    let author: String?
    
    let overview: String?
    
    let genres: [String]
    
    let addedAt: Date
    let released: String?
    
    let size: Int64
    
    let narrator: String?
    let seriesName: String?
    
    let duration: Double
    
    let explicit: Bool
    let abridged: Bool
    
    init(id: String, libraryId: String, name: String, author: String?, overview: String?, genres: [String], addedAt: Date, released: String?, size: Int64, narrator: String?, seriesName: String?, duration: Double, explicit: Bool, abridged: Bool) {
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
