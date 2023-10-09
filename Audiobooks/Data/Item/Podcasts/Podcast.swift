//
//  Podcast.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

class Podcast: Item {
    let explicit: Bool
    let episodeCount: Int
    
    init(id: String, additionalId: String?, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, size: Int64, explicit: Bool, episodeCount: Int) {
        self.explicit = explicit
        self.episodeCount = episodeCount
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    lazy var releaseDate: Date? = {
        if let released = released {
            return try? Date(released, strategy: .iso8601)
        }
        
        return nil
    }()
}
