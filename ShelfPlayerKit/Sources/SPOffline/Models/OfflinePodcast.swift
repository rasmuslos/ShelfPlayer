//
//  OfflinePodcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import Foundation
import SwiftData

@Model
public class OfflinePodcast {
    @Attribute(.unique)
    public let id: String
    public let libraryId: String
    
    public let name: String
    public let author: String?
    
    public let overview: String?
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?

    public let explicit: Bool
    public let episodeCount: Int
    
    public init(id: String, libraryId: String, name: String, author: String?, overview: String?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int) {
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
