//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SPFoundation

internal extension Podcast {
    convenience init(item: AudiobookshelfItem) {
        let addedAt = item.addedAt ?? 0
        let podcastType: PodcastType?
        
        if item.type == "episodic" {
            podcastType = .episodic
        } else if item.type == "serial" {
            podcastType = .serial
        } else {
            podcastType = nil
        }
        
        self.init(
            id: .init(itemID: item.id, episodeID: nil, libraryID: item.libraryId, type: .podcast),
            name: item.media!.metadata.title!,
            authors: item.media?.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: item.media?.metadata.description,
            cover: Cover(item: item),
            genres: item.media?.metadata.genres ?? [],
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: item.media?.metadata.releaseDate, 
            explicit: item.media?.metadata.explicit ?? false,
            episodeCount: item.media?.episodes?.count ?? item.numEpisodes ?? 0,
            incompleteEpisodeCount: item.numEpisodesIncomplete,
            publishingType: podcastType
        )
    }
}
