//
//  HomeRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

struct AudiobookHomeRow: Identifiable {
    let id: String
    let label: String
    let audiobooks: [Audiobook]
}

struct AuthorHomeRow: Identifiable {
    let id: String
    let label: String
    let authors: [Author]
}

struct PodcastHomeRow: Identifiable {
    let id: String
    let label: String
    let podcasts: [Podcast]
}

struct EpisodeHomeRow: Identifiable {
    let id: String
    let label: String
    let episodes: [Episode]
}
