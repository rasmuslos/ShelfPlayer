//
//  Episode+Convert.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "Episode+Convert")

extension Episode {
    convenience init?(payload: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        guard let recentEpisode = payload.recentEpisode else {
            logger.warning("Skipping episode conversion for \(payload.id, privacy: .public): missing recentEpisode")
            return nil
        }
        guard let media = payload.media else {
            logger.warning("Skipping episode conversion for \(payload.id, privacy: .public): missing media")
            return nil
        }
        guard let id = recentEpisode.id else {
            logger.warning("Skipping episode conversion for \(payload.id, privacy: .public): missing recentEpisode.id")
            return nil
        }
        guard let title = recentEpisode.title else {
            logger.warning("Skipping episode conversion for \(payload.id, privacy: .public): missing recentEpisode.title")
            return nil
        }
        guard let podcastTitle = media.metadata.title else {
            logger.warning("Skipping episode conversion for \(payload.id, privacy: .public): missing media.metadata.title")
            return nil
        }

        let addedAt = payload.addedAt ?? 0

        self.init(
            id: .init(primaryID: id, groupingID: payload.id, libraryID: payload.libraryId!, connectionID: connectionID, type: .episode),
            name: title,
            authors: media.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: recentEpisode.description,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: recentEpisode.publishedAt == nil ? nil : String(recentEpisode.publishedAt!),
            size: recentEpisode.size ?? 0,
            duration: recentEpisode.audioFile?.duration ?? 0,
            podcastName: podcastTitle,
            type: .parse(string: recentEpisode.episodeType),
            index: .init(season: recentEpisode.season, episode: recentEpisode.episode ?? String(recentEpisode.index ?? 0)))
    }

    convenience init?(episode: EpisodePayload, item: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        var item = item
        item.recentEpisode = episode

        self.init(payload: item, connectionID: connectionID)
    }

    convenience init(episode: EpisodePayload, podcastName: String? = nil, libraryID: ItemIdentifier.LibraryID, fallbackIndex: Int, connectionID: ItemIdentifier.ConnectionID) {
        self.init(
            id: .init(primaryID: episode.id!, groupingID: episode.libraryItemId, libraryID: libraryID, connectionID: connectionID, type: .episode),
            name: episode.title!,
            authors: episode.podcast?.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: episode.description,
            addedAt: Date(timeIntervalSince1970: 0),
            released: episode.publishedAt == nil ? nil : String(episode.publishedAt!),
            size: episode.size ?? 0,
            duration: episode.audioFile?.duration ?? 0,
            podcastName: podcastName ?? episode.podcast!.metadata.title!,
            type: .parse(string: episode.episodeType),
            index: .init(season: episode.season, episode: String(episode.index ?? fallbackIndex)))
    }
}

private extension Episode.EpisodeType {
    static func parse(string value: String?) -> Self {
        if value == "trailer" {
            .trailer
        } else if value == "bonus" {
            .bonus
        } else {
            .regular
        }
    }
}
