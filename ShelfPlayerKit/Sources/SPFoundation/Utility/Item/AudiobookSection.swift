//
//  AudiobookSection.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.11.24.
//

import Foundation

public enum AudiobookSection {
    case audiobook(audiobook: Audiobook)
    case series(seriesID: ItemIdentifier, seriesName: String, audiobookIDs: [ItemIdentifier])
}

extension AudiobookSection: Hashable {}
extension AudiobookSection: Identifiable {
    public var id: Int {
        self.hashValue
    }
}
