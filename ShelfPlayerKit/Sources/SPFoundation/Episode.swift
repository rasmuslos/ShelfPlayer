//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SwiftSoup

public final class Episode: PlayableItem {
    public let podcastId: String
    public let podcastName: String
    
    public let index: Int
    
    public init(id: String, libraryID: String, name: String, author: String?, description: String?, cover: Cover?, addedAt: Date, released: String?, size: Int64, duration: TimeInterval, podcastId: String, podcastName: String, index: Int) {
        self.podcastId = podcastId
        self.podcastName = podcastName
        self.index = index
        
        super.init(id: id, libraryID: libraryID, type: .episode, name: name, author: author, description: description, cover: cover, genres: [], addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Episode {
    var releaseDate: Date? {
        guard let released = released, let milliseconds = Double(released) else {
            return nil
        }
        
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
    
    var descriptionText: String? {
        guard let description = description, let document = try? SwiftSoup.parse(description) else {
            return nil
        }
        
        return try? document.text()
    }
}
