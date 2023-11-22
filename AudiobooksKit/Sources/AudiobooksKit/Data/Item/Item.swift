//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public class Item: Identifiable {
    public let id: String
    public let libraryId: String
    
    public let name: String
    public let author: String?
    
    public let description: String?
    
    public let image: Image?
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?
    
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
}

extension Item {
    public var sortName: String {
        get {
            var sortName = name.lowercased()
            
            if sortName.starts(with: "a ") {
                let _ = sortName.dropFirst(2)
            }
            if sortName.starts(with: "the ") {
                let _ = sortName.dropFirst(4)
            }
            
            return sortName
        }
    }
}

// MARK: Helper

extension Item {
    public struct Image: Codable {
        public let url: URL
    }
}

// MARK: Progress

extension Item {
    public func setProgress(finished: Bool) async {
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
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Hashable

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
