//
//  HomeRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

public struct AudiobookHomeRow: Identifiable {
    public let id: String
    public let label: String
    public let audiobooks: [Audiobook]
}

public struct AuthorHomeRow: Identifiable {
    public let id: String
    public let label: String
    public let authors: [Author]
}

public struct PodcastHomeRow: Identifiable {
    public let id: String
    public let label: String
    public let podcasts: [Podcast]
}

public struct EpisodeHomeRow: Identifiable {
    public let id: String
    public let label: String
    public let episodes: [Episode]
}
