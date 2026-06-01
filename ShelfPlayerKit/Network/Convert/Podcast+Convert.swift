//
//  Podcast+Convert.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "Podcast+Convert")

internal extension Podcast {
    convenience init?(payload: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        guard let libraryID = payload.libraryId else {
            logger.warning("Skipping podcast conversion for \(payload.id, privacy: .public): missing libraryId")
            return nil
        }
        guard let title = payload.media?.metadata.title else {
            logger.warning("Skipping podcast conversion for \(payload.id, privacy: .public): missing title")
            return nil
        }

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
            id: .init(primaryID: payload.id, groupingID: nil, libraryID: libraryID, connectionID: connectionID, type: .podcast),
            name: title,
            authors: payload.media?.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: payload.media?.metadata.description,
            genres: payload.media?.metadata.genres ?? [],
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: payload.media?.metadata.releaseDate,
            explicit: payload.media?.metadata.explicit ?? false,
            episodeCount: payload.media?.episodes?.count ?? payload.numEpisodes ?? 0,
            incompleteEpisodeCount: payload.numEpisodesIncomplete,
            publishingType: podcastType)
    }
}
