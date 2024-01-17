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
            episodeCount: item.media?.episodes?.count ?? 0,
            type: PodcastType.convertFromAudiobookshelf(type: item.media?.metadata.type)
        )
    }
}
