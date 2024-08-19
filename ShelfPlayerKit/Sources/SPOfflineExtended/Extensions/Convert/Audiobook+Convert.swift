//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation
import SPOffline

internal extension Audiobook {
    convenience init(audiobook: OfflineAudiobook) {
        self.init(
            id: audiobook.id,
            libraryId: audiobook.libraryId,
            name: audiobook.name,
            author: audiobook.author,
            description: audiobook.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.getImageUrl(itemId: audiobook.id)),
            genres: audiobook.genres,
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            duration: audiobook.duration, narrator: audiobook.narrator,
            series: audiobook.seriesName != nil ? ReducedSeries(audiobook.seriesName!) : [],
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
    }
}
