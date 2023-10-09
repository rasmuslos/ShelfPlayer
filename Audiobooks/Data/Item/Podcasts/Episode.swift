//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SwiftSoup

class Episode: PlayableItem {
    let podcastId: String
    let podcastName: String
    
    let index: Int
    let duration: Double
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, size: Int64, podcastId: String, podcastName: String, index: Int, duration: Double) {
        self.podcastId = podcastId
        self.podcastName = podcastName
        self.index = index
        self.duration = duration
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    lazy var releaseDate: Date? = {
        if let released = released {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            return dateFormatter.date(from: released)
        }
        
        return nil
    }()
    
    lazy var formattedReleaseDate: String? = {
        if let releaseDate = releaseDate {
            return String(releaseDate.get(.day)) + "." + String(releaseDate.get(.month)) + "." + String(releaseDate.get(.year))
        }
        
        return nil
    }()
    
    lazy var descriptionText: String? = {
        if let description = description, let document = try? SwiftSoup.parse(description) {
            return try? document.text()
        }
        
        return nil
    }()
}
