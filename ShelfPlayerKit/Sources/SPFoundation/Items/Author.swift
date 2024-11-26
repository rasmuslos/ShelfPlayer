//
//  Author.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Author: Item, @unchecked Sendable {
    public let bookCount: Int
    
    public init(id: ItemIdentifier, name: String, description: String?, addedAt: Date, bookCount: Int) {
        self.bookCount = bookCount
        
        super.init(id: id, name: name, authors: [], description: description, genres: [], addedAt: addedAt, released: nil)
    }
}
