//
//  Placeholder.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation

public extension Episode {
    static let placeholder: Episode = .init(
        id: "placeholder",
        libraryId: "placeholder",
        name: "Placeholder",
        author: nil,
        description: nil,
        cover: nil,
        addedAt: .now,
        released: nil,
        size: 0,
        duration: 0,
        podcastId: "placeholder",
        podcastName: "Placeholder",
        index: 0)
}
