//
//  Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

public class Podcast: Item {
    public let explicit: Bool
    public var episodeCount: Int
    
    public let type: PodcastType?
    
    init(id: String, additionalId: String?, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, explicit: Bool, episodeCount: Int, type: PodcastType?) {
        self.explicit = explicit
        self.episodeCount = episodeCount
        self.type = type
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released)
    }
    
    public private(set) lazy var releaseDate: Date? = {
        if let released = released {
            return try? Date(released, strategy: .iso8601)
        }
        
        return nil
    }()
}

// MARK: Helper

extension Podcast {
    public enum PodcastType {
        case episodic
        case serial
        
        static func convertFromAudiobookshelf(type: String?) -> PodcastType? {
            if let type = type {
                if type == "episodic" {
                    return .episodic
                } else if type == "serial" {
                    return .serial
                }
            }
            
            return nil
        }
    }
}
