//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPBase
import SPOffline

extension Audiobook {
    static func convertFromOffline(audiobook: OfflineAudiobook) -> Audiobook {
        Audiobook(
            id: audiobook.id,
            libraryId: audiobook.libraryId,
            name: audiobook.name,
            author: audiobook.author,
            description: audiobook.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: audiobook.id), type: .local),
            genres: audiobook.genres,
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            duration: audiobook.duration, narrator: audiobook.narrator,
            series: ReducedSeries(
                id: nil,
                name: nil,
                audiobookSeriesName: audiobook.seriesName),
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
    }
}
