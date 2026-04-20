//
//  Episode+ConvertOffline.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation

extension Episode {
    convenience init(downloaded episode: PersistedEpisode) {
        self.init(id: episode.id,
                  name: episode.name,
                  authors: episode.authors,
                  description: episode.overview,
                  addedAt: episode.addedAt,
                  released: episode.released,
                  size: episode.size,
                  duration: episode.duration,
                  podcastName: episode.podcast.name,
                  type: episode.type,
                  index: episode.index)
    }
}
