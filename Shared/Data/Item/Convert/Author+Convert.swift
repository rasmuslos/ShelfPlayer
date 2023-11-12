//
//  Author+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import Foundation

extension Author {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Author {
        Author(
            id: item.id,
            libraryId: item.libraryId!,
            name: item.name!,
            author: item.name,
            description: item.description,
            image: Item.Image.convertFromAudiobookshelf(item: item),
            genres: [], 
            addedAt: Date(timeIntervalSince1970: (item.addedAt ?? 0) / 1000),
            released: nil)
    }
}
