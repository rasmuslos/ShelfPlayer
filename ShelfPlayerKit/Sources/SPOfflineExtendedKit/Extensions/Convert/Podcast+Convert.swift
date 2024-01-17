//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SPBaseKit
import SPOfflineKit

extension Podcast {
    static func convertFromOffline(podcast: OfflinePodcast) -> Podcast {
        Podcast(
            id: podcast.id,
            additionalId: nil,
            libraryId: podcast.libraryId,
            name: podcast.name,
            author: podcast.author,
            description: podcast.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: podcast.id)),
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: 0,
            type: nil)
    }
}
