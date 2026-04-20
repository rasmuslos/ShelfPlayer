//
//  AudiobookSection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.11.24.
//

import Foundation

public enum AudiobookSection: Sendable, Hashable, Identifiable {
    case audiobook(audiobook: Audiobook)
    case series(seriesID: ItemIdentifier, seriesName: String, audiobookIDs: [ItemIdentifier])

    public var audiobook: Audiobook? {
        switch self {
        case .audiobook(let audiobook):
            audiobook
        case .series:
            nil
        }
    }

    public var id: ItemIdentifier {
        switch self {
        case .audiobook(let audiobook):
            audiobook.id
        case .series(let seriesID, _, _):
            seriesID
        }
    }
}
