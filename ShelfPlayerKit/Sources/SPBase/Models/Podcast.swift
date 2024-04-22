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
    
    public let type: PodcastType?
    
    public init(id: String, additionalId: String?, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int, type: PodcastType?) {
        self.explicit = explicit
        self.episodeCount = episodeCount
        self.type = type
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released)
    }
}

extension Podcast {
    public var releaseDate: Date? {
        guard let released = released else { return nil }
        return try? Date(released, strategy: .iso8601)
    }
}

extension Podcast {
    public enum PodcastType {
        case episodic
        case serial
    }
}
