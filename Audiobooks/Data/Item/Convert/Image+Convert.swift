//
//  Image+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

extension Item.Image {
    static func convertFromAudiobookshelf(item: AudiobookshelfClient.AudiobookshelfItem) -> Item.Image? {
        if item.media?.coverPath == nil {
            return nil
        }
        
        return Item.Image(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: "api")
            .appending(path: "items")
            .appending(path: item.id)
            .appending(path: "cover")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token),
            ])
        )
    }
}
