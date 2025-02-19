//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

extension Audiobook {
    convenience init(downloaded audiobook: PersistedAudiobook) {
        self.init(id: audiobook.id,
                  name: audiobook.name,
                  authors: audiobook.authors,
                  description: audiobook.overview,
                  genres: audiobook.genres,
                  addedAt: audiobook.addedAt,
                  released: audiobook.released,
                  size: audiobook.size,
                  duration: audiobook.duration,
                  subtitle: audiobook.subtitle,
                  narrators: audiobook.narrators,
                  series: audiobook.series,
                  explicit: audiobook.explicit,
                  abridged: audiobook.abridged)
    }
}
