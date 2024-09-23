//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SPFoundation
import SPOffline

internal extension Podcast {
    convenience init(_ podcast: OfflinePodcast) {
        self.init(
            id: podcast.id,
            libraryID: podcast.libraryId,
            name: podcast.name,
            author: podcast.author,
            description: podcast.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.imageURL(identifiedBy: podcast.id)),
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: 0,
            publishingType: nil)
    }
}
