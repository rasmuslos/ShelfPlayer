//
//  AudiobookSection+Convert.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import SPFoundation

extension AudiobookSection {
    static func parse(payload: ItemPayload, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) -> Self? {
        if let collapsedSeries = payload.collapsedSeries {
            .series(seriesID: collapsedSeries.id,
                    seriesName: collapsedSeries.name,
                    audiobookIDs: collapsedSeries.libraryItemIds.map { .init(primaryID: $0) })
        } else if let audiobook = Audiobook(payload: payload, libraryID: libraryID, connectionID: connectionID) {
            .audiobook(audiobook: audiobook)
        } else {
            nil
        }
    }
}
