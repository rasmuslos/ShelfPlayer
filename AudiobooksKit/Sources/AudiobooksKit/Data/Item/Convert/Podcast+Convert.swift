//
//  Podcast+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation

extension Podcast {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Podcast {
        Podcast(
            id: item.id,
            additionalId: nil,
            libraryId: item.libraryId!,
            name: item.media!.metadata.title!,
            author: item.media?.metadata.author,
            description: item.media?.metadata.description,
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: item.media?.metadata.genres ?? [],
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: item.media?.metadata.releaseDate, 
            explicit: item.media?.metadata.explicit ?? false,
            episodeCount: item.media?.episodes?.count ?? 0)
    }
    
    static func convertFromOffline(podcast: OfflinePodcast) -> Podcast {
        Podcast(
            id: podcast.id,
            additionalId: nil,
            libraryId: podcast.libraryId,
            name: podcast.name,
            author: podcast.author,
            description: podcast.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: podcast.id)),
            genres: podcast.genres,
            addedAt: podcast.addedAt,
            released: podcast.released,
            explicit: podcast.explicit,
            episodeCount: 0)
    }
}
