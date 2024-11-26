//
//  Placeholder.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation

public extension Episode {
    static let placeholder: Episode = .init(
        id: .init(itemID: "fixture", episodeID: nil, libraryID: "fixture", type: .episode),
        name: "Placeholder",
        authors: [],
        description: nil,
        cover: nil,
        addedAt: .now,
        released: nil,
        size: 0,
        duration: 0,
        podcastName: "Placeholder",
        index: 0)
}
