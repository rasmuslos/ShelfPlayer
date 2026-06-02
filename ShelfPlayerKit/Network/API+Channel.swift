//
//  API+Channel.swift
//  ShelfPlayerKit
//

import Foundation

public extension APIClient {
    /// Resolves a channel — every podcast by the channel's author.
    ///
    /// The author name is recovered from the identifier and run through the
    /// regular library search (`api/libraries/{id}/search`), which returns the
    /// podcasts matching that author. Results are filtered down to podcasts that
    /// actually list the author, so a search hit on title/description alone does
    /// not leak into the channel. This deliberately avoids paging the whole
    /// library — Audiobookshelf has no server-side podcast-author filter.
    func channel(with identifier: ItemIdentifier) async throws -> Channel {
        guard let name = Channel.decodeName(from: identifier) else {
            throw APIClientError.invalidItemType
        }

        let library = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(identifier)
        let podcasts = try await items(in: library, search: name).4.filter { $0.authors.contains(name) }

        guard !podcasts.isEmpty else {
            throw APIClientError.notFound
        }

        return Channel(id: identifier, name: name, podcasts: podcasts.sorted())
    }
}
