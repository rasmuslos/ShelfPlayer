//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

class Item: Identifiable {
    let id: String
    let libraryId: String
    
    let name: String
    let author: String?
    
    let description: String?
    
    let image: Image?
    let genres: [String]
    
    let addedAt: Date
    let released: String?
    
    let size: Int64
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64) {
        self.id = id
        self.libraryId = libraryId
        self.name = name
        self.author = author
        self.description = description
        self.image = image
        self.genres = genres
        self.addedAt = addedAt
        self.released = released
        self.size = size
    }
    
    struct Image {
        let url: URL
    }
}

// MARK: Progress

extension Item {
    func setProgress(finished: Bool) async {
        do {
            if let episode = self as? Episode {
                try await AudiobookshelfClient.shared.setFinished(itemId: episode.podcastId, episodeId: episode.id, finished: finished)
            } else {
                try await AudiobookshelfClient.shared.setFinished(itemId: id, episodeId: nil, finished: finished)
            }
            
            await OfflineManager.shared.setProgress(item: self, finished: finished)
        } catch {
            print("Error while updating progress", error)
        }
    }
}
