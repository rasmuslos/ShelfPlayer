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
    struct AudioFile: Sendable {
        public let ino: String
        public let fileExtension: String
        
        public let offset: TimeInterval
        public let duration: TimeInterval
        
        public init(ino: String, fileExtension: String, offset: TimeInterval, duration: TimeInterval) {
            self.ino = ino
            self.fileExtension = fileExtension
            self.offset = offset
            self.duration = duration
        }
    }
    struct AudioTrack: Sendable, Comparable {
        public let offset: TimeInterval
        public let duration: TimeInterval
        
        public let resource: URL
        
        public init(offset: TimeInterval, duration: TimeInterval, resource: URL) {
            self.offset = offset
            self.duration = duration
            
            self.resource = resource
        }
        
        public static func <(lhs: PlayableItem.AudioTrack, rhs: PlayableItem.AudioTrack) -> Bool {
            lhs.offset < rhs.offset
        }
    }
    
    struct SupplementaryPDF: Identifiable, Sendable {
        public let ino: String
        
        public let fileName: String
        public let fileExtension: String
        
        public init(ino: String, fileName: String, fileExtension: String) {
            self.ino = ino
            self.fileName = fileName
            self.fileExtension = fileExtension
        }
        
        public var id: String {
            ino
        }
        
        public var name: String {
            fileName.replacingOccurrences(of: fileExtension, with: "", range: fileName.range(of: fileExtension, options: .backwards))
        }
    }
}
