//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

@Observable
public class PlayableItem: Item {
    public let size: Int64
    public let duration: Double
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: Double) {
        self.size = size
        self.duration = duration
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released)
    }
}

// MARK: Types

public extension PlayableItem {
    struct AudioTrack: Comparable {
        public let index: Int
        
        public let offset: Double
        public let duration: Double
        
        public let codec: String
        public let mimeType: String
        public let contentUrl: String
        public let fileExtension: String
        
        public init(index: Int, offset: Double, duration: Double, codec: String, mimeType: String, contentUrl: String, fileExtension: String) {
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
    typealias AudioTracks = [AudioTrack]
    
    struct Chapter: Identifiable, Comparable {
        public let id: Int
        public let start: Double
        public let end: Double
        public let title: String
        
        public init(id: Int, start: Double, end: Double, title: String) {
            self.id = id
            self.start = start
            self.end = end
            self.title = title
        }
        
        public static func < (lhs: PlayableItem.Chapter, rhs: PlayableItem.Chapter) -> Bool {
            lhs.start < rhs.start
        }
    }
    typealias Chapters = [Chapter]
}
