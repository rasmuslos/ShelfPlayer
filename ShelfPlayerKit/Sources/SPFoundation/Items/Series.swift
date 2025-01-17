//
//  Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Series: Item, @unchecked Sendable {
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, addedAt: Date) {
        super.init(id: id, name: name, authors: authors, description: description, genres: [], addedAt: addedAt, released: nil)
    }
}
