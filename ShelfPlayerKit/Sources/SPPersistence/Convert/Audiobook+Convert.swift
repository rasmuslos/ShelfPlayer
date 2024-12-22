//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

internal extension Audiobook {
    convenience init(audiobook: OfflineAudiobook) {
        self.init(
            id: .init(itemID: audiobook.id, episodeID: nil, libraryID: audiobook.libraryId, type: .audiobook),
            name: audiobook.name,
            authors: audiobook.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: audiobook.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.imageURL(identifiedBy: audiobook.id)),
            genres: audiobook.genres,
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            duration: audiobook.duration,
            narrators: audiobook.narrator?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: ", ")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? [],
            series: audiobook.seriesName == nil ? [] : SeriesFragment.parse(seriesName: audiobook.seriesName!),
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
    }
}
