//
//  Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

public final class Podcast: Item, @unchecked Sendable {
    public let explicit: Bool
    
    public var episodeCount: Int
    public var incompleteEpisodeCount: Int?
    
    public let publishingType: PodcastType?
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int, incompleteEpisodeCount: Int?, publishingType: PodcastType?) {
        self.explicit = explicit
        
        self.episodeCount = episodeCount
        self.incompleteEpisodeCount = incompleteEpisodeCount
        
        self.publishingType = publishingType
        
        super.init(id: id, name: name, authors: authors, description: description, genres: genres, addedAt: addedAt, released: released)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.explicit = try container.decode(Bool.self, forKey: .explicit)
        self.episodeCount = try container.decode(Int.self, forKey: .episodeCount)
        self.incompleteEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .incompleteEpisodeCount)
        self.publishingType = try container.decodeIfPresent(PodcastType.self, forKey: .publishingType)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(explicit, forKey: .explicit)
        try container.encode(episodeCount, forKey: .episodeCount)
        try container.encodeIfPresent(incompleteEpisodeCount, forKey: .incompleteEpisodeCount)
        try container.encodeIfPresent(publishingType, forKey: .publishingType)
    }
    
    enum CodingKeys: String, CodingKey {
        case explicit
        case episodeCount
        case incompleteEpisodeCount
        case publishingType
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
    enum PodcastType: Int, Codable {
        case episodic
        case serial
    }
}
