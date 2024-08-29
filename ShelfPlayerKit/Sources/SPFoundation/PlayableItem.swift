//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

public class PlayableItem: Item {
    public let size: Int64
    public let duration: TimeInterval
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: TimeInterval) {
        self.size = size
        self.duration = duration
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, cover: cover, genres: genres, addedAt: addedAt, released: released)
    }
}

public extension PlayableItem {
    struct AudioTrack: Comparable {
        public let index: Int
        
        public let offset: TimeInterval
        public let duration: TimeInterval
        
        public let codec: String
        public let mimeType: String
        public let contentUrl: String
        public let fileExtension: String
        
        public init(index: Int, offset: TimeInterval, duration: TimeInterval, codec: String, mimeType: String, contentUrl: String, fileExtension: String) {
            self.index = index
            self.offset = offset
            self.duration = duration
            self.codec = codec
            self.mimeType = mimeType
            self.contentUrl = contentUrl
            self.fileExtension = fileExtension
        }
        
        public static func < (lhs: PlayableItem.AudioTrack, rhs: PlayableItem.AudioTrack) -> Bool {
            lhs.index < rhs.index
        }
    }
    
    struct Chapter: Identifiable, Comparable {
        public let id: Int
        public let start: TimeInterval
        public let end: TimeInterval
        public let title: String
        
        public init(id: Int, start: TimeInterval, end: TimeInterval, title: String) {
            self.id = id
            self.start = start
            self.end = end
            self.title = title
        }
        
        public static func < (lhs: PlayableItem.Chapter, rhs: PlayableItem.Chapter) -> Bool {
            lhs.start < rhs.start
        }
    }
}
