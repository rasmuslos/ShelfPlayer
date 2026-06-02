//
//  Channel.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.06.26.
//

import Foundation

/// A podcast channel: every podcast that shares the same author.
///
/// Audiobookshelf has no channel — or even author — entity for podcasts; a
/// podcast only carries a free-text `author` string. A `Channel` is therefore a
/// client-derived grouping whose identity is the author name (base64-encoded
/// into the `ItemIdentifier`, exactly like ``Person/convertNarratorToID(_:libraryID:connectionID:)``).
public final class Channel: Item, @unchecked Sendable {
    public var podcasts: [Podcast]

    public init(id: ItemIdentifier, name: String, podcasts: [Podcast]) {
        self.podcasts = podcasts

        super.init(id: id, name: name, authors: [], description: nil, genres: [], addedAt: .distantPast, released: nil)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.podcasts = try container.decode([Podcast].self, forKey: .podcasts)

        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(podcasts, forKey: .podcasts)
    }

    enum CodingKeys: String, CodingKey {
        case podcasts
    }
}

// MARK: - Identity

public extension Channel {
    /// Derives a stable ``ItemIdentifier`` for the channel of the given author.
    ///
    /// The author name is URL-safe base64 encoded into the `primaryID`, mirroring
    /// ``Person/convertNarratorToID(_:libraryID:connectionID:)`` so channels are
    /// addressable and navigable without a server-side identifier.
    static func convertNameToID(_ name: String, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) -> ItemIdentifier {
        var base64 = Data(name.utf8).base64EncodedString()

        base64 = base64.replacingOccurrences(of: "+", with: "%2B")
        base64 = base64.replacingOccurrences(of: "/", with: "%2F")
        base64 = base64.replacingOccurrences(of: "=", with: "%3D")

        return ItemIdentifier(primaryID: base64,
                              groupingID: nil,
                              libraryID: libraryID,
                              connectionID: connectionID,
                              type: .channel)
    }

    /// The monogram shown on a channel's (artwork-less) cover: the first letter
    /// of each word, up to three words. A single-word name yields a single
    /// letter (`Deutschlandfunk` → `D`, `DER SPIEGEL` → `DS`).
    static func monogram(for name: String) -> String {
        let words = name.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        let initials = words.prefix(3).compactMap(\.first).map(String.init).joined().uppercased()

        return initials.isEmpty ? String(name.prefix(1)).uppercased() : initials
    }

    /// Recovers the author name encoded into a channel ``ItemIdentifier`` by
    /// ``convertNameToID(_:libraryID:connectionID:)``.
    static func decodeName(from identifier: ItemIdentifier) -> String? {
        var base64 = identifier.primaryID

        base64 = base64.replacingOccurrences(of: "%2B", with: "+")
        base64 = base64.replacingOccurrences(of: "%2F", with: "/")
        base64 = base64.replacingOccurrences(of: "%3D", with: "=")

        guard let data = Data(base64Encoded: base64), let name = String(data: data, encoding: .utf8) else {
            return nil
        }

        return name
    }
}
