//
//  Image+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SPFoundation

extension Cover {
    init(item: AudiobookshelfItem, size: CoverSize = .normal) {
        let isAuthor = item.name != nil && item.imagePath != nil
        
        self.init(type: .remote, size: size, url: AudiobookshelfClient.shared.serverUrl
            .appending(path: "api")
            .appending(path: isAuthor ? "authors" : "items")
            .appending(path: item.id)
            .appending(path: isAuthor ? "image" : "cover")
            .appending(queryItems: [
                URLQueryItem(name: "width", value: "\(size.dimensions)"),
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token),
            ])
        )
    }
    
    init(podcast: AudiobookshelfPodcastEpisode.AudiobookshelfItemPodcast, size: CoverSize = .normal) {
        self.init(type: .remote, size: size, url: AudiobookshelfClient.shared.serverUrl
            .appending(path: "api")
            .appending(path: "items")
            .appending(path: podcast.libraryItemId)
            .appending(path: "cover")
            .appending(queryItems: [
                URLQueryItem(name: "width", value: "1000"),
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token),
            ])
        )
    }
}
