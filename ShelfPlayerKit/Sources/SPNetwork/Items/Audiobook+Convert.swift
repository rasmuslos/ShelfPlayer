//
//  Audiobook+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension Audiobook {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Audiobook? {
        // gibe items the benefit of the doubt while filtering out ebooks
        guard item.media?.numAudioFiles ?? item.media?.audioFiles?.count ?? 1 > 0 else {
            return nil
        }
        
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
            series: {
                var resolved = [ReducedSeries]()
                
                if let series = item.media?.metadata.series, !series.isEmpty {
                    resolved += series.map {
                        let name = $0.name!
                        
                        if let seq = $0.sequence, let sequence = Float(seq) {
                            return Audiobook.ReducedSeries(id: $0.id, name: name, sequence: sequence)
                        } else {
                            return Audiobook.ReducedSeries(id: $0.id, name: name, sequence: nil)
                        }
                    }
                }
                if let seriesName = item.media?.metadata.seriesName {
                    let series = ReducedSeries.convert(seriesName: seriesName)
                    
                    for series in series {
                        if !resolved.contains(where: { $0.name == series.name }) {
                            resolved.append(series)
                        }
                    }
                }
                
                return resolved
            }(),
            explicit: item.media?.metadata.explicit ?? false,
            abridged: item.media?.metadata.abridged ?? false)
    }
}
