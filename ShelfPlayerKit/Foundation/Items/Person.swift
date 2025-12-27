//
//  Author.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Person: Item, @unchecked Sendable {
    public let bookCount: Int
    
    public init(id: ItemIdentifier, name: String, description: String?, addedAt: Date, bookCount: Int) {
        self.bookCount = bookCount
        super.init(id: id, name: name, authors: [], description: description, genres: [], addedAt: addedAt, released: nil)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bookCount = try container.decode(Int.self, forKey: .bookCount)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bookCount, forKey: .bookCount)
    }
    
    enum CodingKeys: String, CodingKey {
        case bookCount
    }
}
