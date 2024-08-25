//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation
import SPOffline

internal extension Episode {
    convenience init(_ episode: OfflineEpisode) {
        self.init(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            description: episode.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.imageURL(identifiedBy: episode.podcast.id)),
            addedAt: episode.addedAt,
            released: episode.released,
            size: 0,
            duration: episode.duration, podcastId: episode.podcast.id,
            podcastName: episode.podcast.name,
            index: episode.index)
    }
}
