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
            libraryId: item.libraryId!,
            name: item.recentEpisode!.title!,
            author: item.media?.metadata.author,
            description: item.recentEpisode?.description,
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: [],
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: item.recentEpisode?.pubDate,
            size: item.recentEpisode?.size ?? 0,
            podcastId: item.id,
            podcastName: item.media!.metadata.title!,
            index: item.recentEpisode?.index ?? 0,
            duration: item.recentEpisode?.audioFile?.duration ?? 0)
    }
    
    static func convertFromAudiobookshelf(podcastEpisode: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfPodcastEpisode, item: AudiobookshelfClient.AudiobookshelfItem) -> Episode {
        Episode(
            id: podcastEpisode.id!,
            libraryId: item.libraryId!,
            name: podcastEpisode.title!,
            author: item.media?.metadata.author!,
            description: podcastEpisode.description,
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: [],
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: podcastEpisode.pubDate,
            size: podcastEpisode.size ?? 0,
            podcastId: item.id,
            podcastName: item.media!.metadata.title!,
            index: podcastEpisode.index ?? 0,
            duration: podcastEpisode.audioFile?.duration ?? 0)
    }
}
