//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

public class PlayableItem: Item, @unchecked Sendable {
    public let size: Int64
    public let duration: TimeInterval
    
    init(id: ItemIdentifier, name: String, authors: [String], description: String?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: TimeInterval) {
        self.size = size
        self.duration = duration
        
        super.init(id: id, name: name, authors: authors, description: description, genres: genres, addedAt: addedAt, released: released)
    }
}

public extension PlayableItem {
    struct AudioTrack: Comparable {
        public let index: Int
        
        public let offset: TimeInterval
        public let duration: TimeInterval
        
        public let contentUrl: String
        
        public init(index: Int, offset: TimeInterval, duration: TimeInterval, contentUrl: String) {
            self.index = index
            self.offset = offset
            self.duration = duration
            self.contentUrl = contentUrl
        }
        
        public static func <(lhs: PlayableItem.AudioTrack, rhs: PlayableItem.AudioTrack) -> Bool {
            lhs.index < rhs.index
        }
    }
}
