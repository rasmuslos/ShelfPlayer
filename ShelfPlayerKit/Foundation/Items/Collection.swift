//
//  Collection.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.07.25.
//

import Foundation

public final class ItemCollection: Item, @unchecked Sendable {
    public let items: [Item]
    
    public init(id: ItemIdentifier, name: String, description: String?, addedAt: Date, items: [Item]) {
        self.items = items
        
        super.init(id: id, name: name, authors: [], description: description, genres: [], addedAt: addedAt, released: nil)
    }
    
    required init(from decoder: Decoder) throws {
        self.items = try decoder.container(keyedBy: CodingKeys.self).decode([Item].self, forKey: .items)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
    }
    
    enum CodingKeys: String, CodingKey {
        case items
    }
    
    public enum CollectionType: Codable, Sendable {
        case collection
        case playlist
        
        var itemType: ItemIdentifier.ItemType {
            switch self {
                case .collection:
                        .collection
                case .playlist:
                        .playlist
            }
        }
        var apiValue: String {
            switch self {
                case .collection:
                    "collections"
                case .playlist:
                    "playlists"
            }
        }
    }
}

public extension ItemCollection {
    var audiobooks: [Audiobook]? {
        items as? [Audiobook]
    }
    var episodes: [Episode]? {
        items as? [Episode]
    }
}
