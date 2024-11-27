//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation

extension Episode {
    convenience init?(payload: ItemPayload) {
        guard let recentEpisode = payload.recentEpisode,
              let media = payload.media,
              let id = recentEpisode.id,
              let title = recentEpisode.title,
              let podcastTitle = media.metadata.title else {
            return nil
        }
        
        let addedAt = payload.addedAt ?? 0
        
        self.init(
            id: .init(primaryID: id, groupingID: payload.id, libraryID: payload.libraryId, type: .episode),
            name: title,
            authors: media.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: recentEpisode.description,
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: recentEpisode.publishedAt == nil ? nil : String(recentEpisode.publishedAt!),
            size: recentEpisode.size ?? 0,
            duration: recentEpisode.audioFile?.duration ?? 0,
            podcastName: podcastTitle,
            index: recentEpisode.index ?? 0)
    }
    convenience init?(episode: EpisodePayload, item: ItemPayload) {
        var item = item
        item.recentEpisode = episode
        
        self.init(payload: item)
    }
    
    convenience init(episode: EpisodePayload) {
        self.init(
            id: .init(primaryID: episode.id!, groupingID: episode.podcast!.id, libraryID: episode.libraryId, type: .episode),
            name: episode.title!,
            authors: episode.podcast?.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: episode.description,
            addedAt: Date(timeIntervalSince1970: 0),
            released: episode.publishedAt == nil ? nil : String(episode.publishedAt!),
            size: episode.size ?? 0,
            duration: episode.audioFile?.duration ?? 0,
            podcastName: episode.podcast!.metadata.title!,
            index: episode.index ?? 0)
    }
}
