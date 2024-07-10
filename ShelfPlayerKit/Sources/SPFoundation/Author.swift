//
//  Author.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Author: Item {
    public convenience init(id: String, libraryId: String, name: String, description: String?, cover: Cover?, addedAt: Date) {
        self.init(id: id, libraryId: libraryId, name: name, author: nil, description: description, cover: cover, genres: [], addedAt: addedAt, released: nil)
    }
}
