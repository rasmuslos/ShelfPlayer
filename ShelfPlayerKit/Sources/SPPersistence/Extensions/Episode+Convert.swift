//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation

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
                  index: episode.index)
    }
}
