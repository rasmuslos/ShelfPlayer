//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension Audiobook {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Audiobook {
        return Audiobook(
            id: item.id,
            libraryId: item.libraryId!,
            name: item.media!.metadata.title!,
            author: item.media?.metadata.authorName?.trim(),
            description: item.media?.metadata.description?.trim(),
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: item.media?.metadata.genres ?? [],
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: item.media?.metadata.publishedYear != nil ? try? Date(item.media!.metadata.publishedYear!, strategy: .dateTime) : nil,
            size: item.size!,
            narrator: item.media?.metadata.narratorName?.trim(),
            series: Audiobook.ReducedSeries(
                id: item.media?.metadata.series?.id,
                name: item.media?.metadata.series?.name,
                audiobookSeriesName: item.media?.metadata.seriesName?.trim()),
            duration: item.media!.duration!,
            explicit: item.media?.metadata.explicit ?? false,
            abridged: item.media?.metadata.abridged ?? false)
    }
}
