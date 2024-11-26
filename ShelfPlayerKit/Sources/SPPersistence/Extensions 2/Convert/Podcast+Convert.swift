//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SPFoundation
import SPPersistence

internal extension Podcast {
    convenience init(_ podcast: OfflinePodcast) {
        self.init(
            id: .init(itemID: podcast.id, episodeID: nil, libraryID: podcast.libraryId, type: .podcast),
            name: podcast.name,
            authors: podcast.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: podcast.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.imageURL(identifiedBy: podcast.id)),
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: 0,
            incompleteEpisodeCount: nil,
            publishingType: nil)
    }
}
