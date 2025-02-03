//
//  AudiobookSection.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.11.24.
//

import Foundation

public enum AudiobookSection: Sendable {
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
}

extension AudiobookSection: Hashable {}
extension AudiobookSection: Identifiable {
    public var id: Int {
        self.hashValue
    }
}
