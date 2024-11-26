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
            id: .init(itemID: episode.id, episodeID: episode.podcast.id, libraryID: episode.libraryId, type: .episode),
            name: episode.name,
            authors: episode.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: episode.overview,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.imageURL(identifiedBy: episode.podcast.id)),
            addedAt: episode.addedAt,
            released: episode.released,
            size: 0,
            duration: episode.duration,
            podcastName: episode.podcast.name,
            index: episode.index)
    }
}
