//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation

extension Episode {
    convenience init?(payload: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        guard let recentEpisode = payload.recentEpisode,
              let media = payload.media,
              let id = recentEpisode.id,
              let title = recentEpisode.title,
              let podcastTitle = media.metadata.title else {
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
            index: .init(season: recentEpisode.season, episode: String(recentEpisode.index ?? 0)))
    }
    convenience init?(episode: EpisodePayload, item: ItemPayload, connectionID: ItemIdentifier.ConnectionID) {
        var item = item
        item.recentEpisode = episode
        
        self.init(payload: item, connectionID: connectionID)
    }
    
    convenience init(episode: EpisodePayload, connectionID: ItemIdentifier.ConnectionID) {
        self.init(
            id: .init(primaryID: episode.id!, groupingID: episode.libraryItemId, libraryID: episode.libraryId!, connectionID: connectionID, type: .episode),
            name: episode.title!,
            authors: episode.podcast?.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: episode.description,
            addedAt: Date(timeIntervalSince1970: 0),
            released: episode.publishedAt == nil ? nil : String(episode.publishedAt!),
            size: episode.size ?? 0,
            duration: episode.audioFile?.duration ?? 0,
            podcastName: episode.podcast!.metadata.title!,
            index: .init(season: episode.season, episode: String(episode.index ?? 0)))
    }
}
