//
//  AudiobookSection+Convert.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import SPFoundation

extension AudiobookSection {
     static func parse(item: ItemPayload) -> Self? {
        if let collapsedSeries = item.collapsedSeries {
            .series(seriesID: collapsedSeries.id, seriesName: collapsedSeries.name, audiobookIDs: collapsedSeries.libraryItemIds.map { .init(primaryID: $0, groupingID: nil, libraryID: item.libraryId, type: .audiobook) })
        } else if let audiobook = Audiobook(item: item) {
            .audiobook(audiobook: audiobook)
        } else {
            nil
        }
    }
}
