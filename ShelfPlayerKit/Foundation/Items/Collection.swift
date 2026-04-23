//
//  Collection.swift
//  ShelfPlayerKit
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
        // `items` is heterogeneous — audiobook collections contain Audiobooks,
        // playlists contain Audiobooks or Episodes. Decoding `[Item]` directly
        // would discard subclass fields because Swift's Codable always
        // instantiates the declared static type. Route through `AnyItem`,
        // which dispatches on `ItemIdentifier.type` to instantiate the
        // correct subclass.
        let wrapped = try decoder.container(keyedBy: CodingKeys.self).decode([AnyItem].self, forKey: .items)
        self.items = wrapped.map(\.item)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items.map(AnyItem.init), forKey: .items)
    }

    enum CodingKeys: String, CodingKey {
        case items
    }
}

// MARK: - Polymorphic item Codable

/// Codable wrapper that preserves the concrete subclass of an `Item` across
/// a Codable round-trip. The encoded JSON is identical to what the concrete
/// subclass would emit — the wrapper only affects decoding, where it peeks
/// at `id.type` on the encoded payload and instantiates the matching
/// subclass before forwarding the decoder.
struct AnyItem: Codable, Sendable {
    let item: Item

    init(_ item: Item) {
        self.item = item
    }

    private enum PeekKey: String, CodingKey {
        // Every Item encodes its `id` (an `ItemIdentifier`), which carries
        // `type`. We reuse that discriminator rather than adding a separate
        // type tag, so the JSON shape is unchanged.
        case id
    }

    init(from decoder: Decoder) throws {
        let peek = try decoder.container(keyedBy: PeekKey.self)
        let id = try peek.decode(ItemIdentifier.self, forKey: .id)

        switch id.type {
        case .audiobook:
            self.item = try Audiobook(from: decoder)
        case .episode:
            self.item = try Episode(from: decoder)
        case .podcast:
            self.item = try Podcast(from: decoder)
        case .series:
            self.item = try Series(from: decoder)
        case .author, .narrator:
            self.item = try Person(from: decoder)
        case .collection, .playlist:
            self.item = try ItemCollection(from: decoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try item.encode(to: encoder)
    }
}

// MARK: - Collection Type

public extension ItemCollection {
    enum CollectionType: Codable, Hashable, Identifiable, Sendable {
        case collection
        case playlist

        public var id: Self { self }

        public var itemType: ItemIdentifier.ItemType {
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

// MARK: - Helpers

public extension ItemCollection {
    var audiobooks: [Audiobook]? {
        items as? [Audiobook]
    }

    var episodes: [Episode]? {
        items as? [Episode]
    }
}
