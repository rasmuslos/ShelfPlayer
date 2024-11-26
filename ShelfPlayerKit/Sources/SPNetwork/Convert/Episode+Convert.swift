//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation
import SPFoundation

internal extension Episode {
    convenience init?(item: AudiobookshelfItem) {
        guard let recentEpisode = item.recentEpisode, let media = item.media, let id = recentEpisode.id, let title = recentEpisode.title, let podcastTitle = media.metadata.title else {
            return nil
        }
        
        let addedAt = item.addedAt ?? 0
        
        self.init(
            id: .init(itemID: item.id, episodeID: id, libraryID: item.libraryId, type: .episode),
            name: title,
            authors: media.metadata.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: recentEpisode.description,
            cover: Cover(item: item),
            addedAt: Date(timeIntervalSince1970: addedAt / 1000),
            released: recentEpisode.publishedAt == nil ? nil : String(recentEpisode.publishedAt!),
            size: recentEpisode.size ?? 0,
            duration: recentEpisode.audioFile?.duration ?? 0,
            podcastName: podcastTitle,
            index: recentEpisode.index ?? 0)
    }
    convenience init?(episode: AudiobookshelfPodcastEpisode, item: AudiobookshelfItem) {
        var item = item
        item.recentEpisode = episode
        
        self.init(item: item)
    }
    
    convenience init(episode: AudiobookshelfPodcastEpisode) {
        self.init(
            id: .init(itemID: episode.podcast!.id, episodeID: episode.id, libraryID: episode.libraryId, type: .episode),
            name: episode.title!,
            authors: episode.podcast?.author?.split(separator: ", ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? [],
            description: episode.description,
            cover: Cover(podcast: episode.podcast!),
            addedAt: Date(timeIntervalSince1970: 0),
            released: episode.publishedAt == nil ? nil : String(episode.publishedAt!),
            size: episode.size ?? 0,
            duration: episode.audioFile?.duration ?? 0,
            podcastName: episode.podcast!.metadata.title!,
            index: episode.index ?? 0)
    }
}
