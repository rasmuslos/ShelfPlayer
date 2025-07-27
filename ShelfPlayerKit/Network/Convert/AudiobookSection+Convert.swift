//
//  AudiobookSection+Convert.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

extension AudiobookSection {
    static func parse(payload: ItemPayload, libraryID: ItemIdentifier.LibraryID, connectionID: ItemIdentifier.ConnectionID) -> Self? {
        if let collapsedSeries = payload.collapsedSeries {
            .series(seriesID: .init(primaryID: collapsedSeries.id,
                                    groupingID: nil,
                                    libraryID: libraryID,
                                    connectionID: connectionID,
                                    type: .series),
                    seriesName: collapsedSeries.name,
                    audiobookIDs: collapsedSeries.libraryItemIds.map { .init(primaryID: $0,
                                                                             groupingID: nil,
                                                                             libraryID: libraryID,
                                                                             connectionID: connectionID,
                                                                             type: .audiobook) })
        } else if let audiobook = Audiobook(payload: payload, libraryID: libraryID, connectionID: connectionID) {
            .audiobook(audiobook: audiobook)
        } else {
            nil
        }
    }
}
