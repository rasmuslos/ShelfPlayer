//
//  Episode+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import Foundation

extension Episode {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Episode {
        Episode(
            id: item.recentEpisode!.id!,
            additionalId: item.recentEpisode!.podcastId!,
            libraryId: item.libraryId!,
            name: item.recentEpisode!.title!,
            author: item.media?.metadata.author,
            description: item.recentEpisode?.description,
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: [],
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: item.recentEpisode?.pubDate,
            size: item.recentEpisode?.size ?? 0,
            podcastName: item.media!.metadata.title!,
            duration: item.recentEpisode?.audioFile?.duration ?? 0)
    }
}
