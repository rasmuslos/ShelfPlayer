//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftUI

@Observable
public class Item: Identifiable {
    public let id: String
    public let libraryId: String
    
    public let name: String
    public let author: String?
    
    public let description: String?
    
    public let cover: Cover?
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?) {
        self.id = id
        self.libraryId = libraryId
        self.name = name
        self.author = author
        self.description = description
        self.cover = cover
        self.genres = genres
        self.addedAt = addedAt
        self.released = released
    }
}

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
