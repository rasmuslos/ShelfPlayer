//
//  Placeholder.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation

public extension Audiobook {
    static let placeholder: Audiobook = .init(
        id: .init(primaryID: "fixture", groupingID: "fixture", libraryID: "fixture", connectionID: "fixture", type: .audiobook),
        name: "Placeholder",
        authors: [],
        description: nil,
        genres: [],
        addedAt: .now,
        released: nil,
        size: nil,
        duration: 0,
        subtitle: nil,
        narrators: [],
        series: [],
        explicit: false,
        abridged: false)
}

public extension Episode {
    static let placeholder: Episode = .init(
        id: .init(primaryID: "placeholder", groupingID: "placeholder", libraryID: "placeholder", connectionID: "placeholder", type: .episode),
        name: "Placeholder",
        authors: [],
        description: nil,
        addedAt: .now,
        released: nil,
        size: 0,
        duration: 0,
        podcastName: "Placeholder",
        type: .regular,
        index: .init(season: nil, episode: "placeholder"))
}
