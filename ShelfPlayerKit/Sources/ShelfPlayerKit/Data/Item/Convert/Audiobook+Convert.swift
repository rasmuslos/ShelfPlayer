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
            released: item.media?.metadata.publishedYear,
            size: item.size!,
            duration: item.media?.duration ?? 0, narrator: item.media?.metadata.narratorName?.trim(),
            series: Audiobook.ReducedSeries(
                id: item.media?.metadata.series?.id,
                name: item.media?.metadata.series?.name,
                audiobookSeriesName: item.media?.metadata.seriesName?.trim()),
            explicit: item.media?.metadata.explicit ?? false,
            abridged: item.media?.metadata.abridged ?? false)
    }
    
    static func convertFromOffline(audiobook: OfflineAudiobook) -> Audiobook {
        Audiobook(
            id: audiobook.id,
            libraryId: audiobook.libraryId,
            name: audiobook.name,
            author: audiobook.author,
            description: audiobook.overview,
            image: Item.Image(url: DownloadManager.shared.getImageUrl(itemId: audiobook.id)),
            genres: audiobook.genres,
            addedAt: audiobook.addedAt,
            released: audiobook.released,
            size: audiobook.size,
            duration: audiobook.duration, narrator: audiobook.narrator,
            series: ReducedSeries(
                id: nil,
                name: nil,
                audiobookSeriesName: audiobook.seriesName),
            explicit: audiobook.explicit,
            abridged: audiobook.abridged)
    }
}
