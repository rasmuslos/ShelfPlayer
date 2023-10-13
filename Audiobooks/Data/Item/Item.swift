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
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?) {
        self.id = id
        self.libraryId = libraryId
        self.name = name
        self.author = author
        self.description = description
        self.image = image
        self.genres = genres
        self.addedAt = addedAt
        self.released = released
    }
    
    struct Image: Codable {
        let url: URL
    }
    
    private(set) lazy var sortName: String = {
        var sortName = name.lowercased()
        
        if sortName.starts(with: "a ") {
            let _ = sortName.dropFirst(2)
        }
        if sortName.starts(with: "the ") {
            let _ = sortName.dropFirst(4)
        }
        
        return sortName
    }()
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

// MARK: Equatable

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Hashable

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
