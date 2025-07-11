//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation


internal extension Podcast {
    convenience init(payload: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        let addedAt = payload.addedAt ?? 0
        let podcastType: PodcastType?
        
        if payload.type == "episodic" {
            podcastType = .episodic
        } else if payload.type == "serial" {
            podcastType = .serial
        } else {
            podcastType = nil
        }
        
        self.init(
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: payload.libraryId!, connectionID: connectionID, type: .podcast),
            name: payload.media!.metadata.title!,
            authors: payload.media?.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: payload.media?.metadata.description,
            genres: payload.media?.metadata.genres ?? [],
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: payload.media?.metadata.releaseDate, 
            explicit: payload.media?.metadata.explicit ?? false,
            episodeCount: payload.media?.episodes?.count ?? payload.numEpisodes ?? 0,
            incompleteEpisodeCount: payload.numEpisodesIncomplete,
            publishingType: podcastType
        )
    }
}
