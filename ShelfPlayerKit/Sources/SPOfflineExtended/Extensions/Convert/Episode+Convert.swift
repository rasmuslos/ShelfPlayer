//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation
import SPOffline

extension Episode {
    static func convertFromOffline(episode: OfflineEpisode) -> Episode {
        Episode(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            description: episode.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: episode.podcast.id), type: .local),
            genres: [],
            addedAt: episode.addedAt,
            released: episode.released,
            size: 0,
            duration: episode.duration, podcastId: episode.podcast.id,
            podcastName: episode.podcast.name,
            index: episode.index)
    }
}
