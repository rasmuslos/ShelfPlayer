//
//  Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

public final class Series: Item, @unchecked Sendable {
    public var audiobooks: [Audiobook]
    
    public init(id: ItemIdentifier, name: String, authors: [String], description: String?, addedAt: Date, audiobooks: [Audiobook]) {
        self.audiobooks = audiobooks
        
        super.init(id: id, name: name, authors: authors, description: description, genres: [], addedAt: addedAt, released: nil)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audiobooks = try container.decode([Audiobook].self, forKey: .audiobooks)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audiobooks, forKey: .audiobooks)
    }
    
    enum CodingKeys: String, CodingKey {
        case audiobooks
    }
}
