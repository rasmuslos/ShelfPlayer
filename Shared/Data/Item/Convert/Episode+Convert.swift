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
            released: item.recentEpisode?.publishedAt != nil ? String(item.recentEpisode!.publishedAt!) : nil,
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
            released: podcastEpisode.publishedAt != nil ? String(podcastEpisode.publishedAt!) : nil,
            size: podcastEpisode.size ?? 0,
            podcastId: item.id,
            podcastName: item.media!.metadata.title!,
            index: podcastEpisode.index ?? 0,
            duration: podcastEpisode.audioFile?.duration ?? 0)
    }
    
    static func convertFromAudiobookshelf(episode: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfPodcastEpisode) -> Episode {
        Episode(
            id: episode.id!,
            libraryId: episode.libraryItemId!,
            name: episode.title!,
            author: episode.podcast?.author,
            description: episode.description,
            image: Item.Image.convertFromAudiobookshelf(podcast: episode.podcast!),
            genres: [],
            addedAt: Date(),
            released: episode.publishedAt != nil ? String(episode.publishedAt!) : nil,
            size: episode.size ?? 0,
            podcastId: episode.podcast!.libraryItemId,
            podcastName: episode.podcast!.metadata.title!,
            index: episode.index ?? 0,
            duration: episode.audioFile?.duration ?? 0)
    }
}

extension Episode {
    static func convertFromOffline(episode: OfflineEpisode) -> Episode {
        Episode(
            id: episode.id,
            libraryId: episode.libraryId,
            name: episode.name,
            author: episode.author,
            description: episode.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: episode.podcast.id)),
            genres: [],
            addedAt: episode.addedAt,
            released: episode.released,
            size: 0,
            podcastId: episode.podcast.id,
            podcastName: episode.podcast.name,
            index: episode.index,
            duration: episode.duration)
    }
}
