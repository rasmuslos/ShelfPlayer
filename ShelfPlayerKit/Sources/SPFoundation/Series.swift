//
//  Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Series: Item {
    public let covers: [Cover]
    
    public init(id: String, libraryId: String, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?, covers: [Cover]) {
        self.covers = covers
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, cover: cover, genres: genres, addedAt: addedAt, released: released)
    }
}
