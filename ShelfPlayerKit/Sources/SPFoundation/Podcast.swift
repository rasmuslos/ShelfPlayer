//
//  Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

public final class Podcast: Item {
    public let explicit: Bool
    public var episodeCount: Int
    
    public let publishingType: PodcastType?
    
    public init(id: String, libraryID: String, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int, publishingType: PodcastType?) {
        self.explicit = explicit
        self.episodeCount = episodeCount
        self.publishingType = publishingType
        
        super.init(id: id, libraryID: libraryID, type: .podcast, name: name, author: author, description: description, cover: cover, genres: genres, addedAt: addedAt, released: released)
    }
}

public extension Podcast {
    var releaseDate: Date? {
        guard let released = released else {
            return nil
        }
        
        return try? Date(released, strategy: .iso8601)
    }
}

public extension Podcast {
    enum PodcastType {
        case episodic
        case serial
    }
}
