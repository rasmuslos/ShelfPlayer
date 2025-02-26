//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SPFoundation

extension Podcast {
    convenience init(downloaded podcast: PersistedPodcast) {
        self.init(id: podcast.id,
                  name: podcast.name,
                  authors: podcast.authors,
                  description: podcast.overview,
                  genres: podcast.genres,
                  addedAt: podcast.addedAt,
                  released: podcast.released,
                  explicit: podcast.explicit,
                  episodeCount: podcast.totalEpisodeCount,
                  incompleteEpisodeCount: nil,
                  publishingType: podcast.publishingType)
    }
}
