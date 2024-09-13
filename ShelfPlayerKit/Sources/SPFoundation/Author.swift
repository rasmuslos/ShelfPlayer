//
//  Author.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Author: Item {
    public let bookCount: Int
    
    public init(id: String, libraryId: String, name: String, description: String?, cover: Cover?, addedAt: Date, bookCount: Int) {
        self.bookCount = bookCount
        
        super.init(id: id, libraryId: libraryId, type: .author, name: name, author: nil, description: description, cover: nil, genres: [], addedAt: addedAt, released: nil)
    }
}
