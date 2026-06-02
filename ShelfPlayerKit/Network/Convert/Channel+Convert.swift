//
//  Channel+Convert.swift
//  ShelfPlayerKit
//

import Foundation

public extension Channel {
    /// Groups podcasts into channels by their author strings.
    ///
    /// A podcast with multiple authors (`"A, B"`) contributes to one channel per
    /// author, so it appears under both. Channels and their podcasts are returned
    /// sorted by name.
    static func grouped(from podcasts: [Podcast]) -> [Channel] {
        guard let first = podcasts.first else {
            return []
        }

        let libraryID = first.id.libraryID
        let connectionID = first.id.connectionID

        var byAuthor = [String: [Podcast]]()

        for podcast in podcasts {
            for author in podcast.authors {
                let name = author.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !name.isEmpty else {
                    continue
                }

                byAuthor[name, default: []].append(podcast)
            }
        }

        return byAuthor.map { name, podcasts in
            Channel(id: convertNameToID(name, libraryID: libraryID, connectionID: connectionID),
                    name: name,
                    podcasts: podcasts.sorted())
        }.sorted()
    }
}
