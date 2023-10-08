//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SwiftSoup

class Episode: Item {
    let podcastName: String
    let duration: Double
    
    init(id: String, additionalId: String?, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, size: Int64, podcastName: String, duration: Double) {
        self.podcastName = podcastName
        self.duration = duration
        
        super.init(id: id, additionalId: nil, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    lazy var releaseDate: Date? = {
        if let released = released {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            return dateFormatter.date(from: released)
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
