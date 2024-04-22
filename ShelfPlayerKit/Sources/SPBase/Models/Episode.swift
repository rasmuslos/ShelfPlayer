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
    
    public init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, size: Int64, duration: Double, podcastId: String, podcastName: String, index: Int) {
        self.podcastId = podcastId
        self.podcastName = podcastName
        self.index = index
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size, duration: duration)
    }
}

public extension Episode {
    var releaseDate: Date? {
        guard let released = released, let milliseconds = Double(released) else { return nil }
        return Date(timeIntervalSince1970: milliseconds / 1000)
    }
    
    var descriptionText: String? {
        guard let description = description, let document = try? SwiftSoup.parse(description) else { return nil }
        return try? document.text()
    }
}
