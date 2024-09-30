//
//  Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import SwiftUI

@Observable
public class Item: Identifiable {
    public let id: String
    public let libraryID: String
    
    public let type: ItemType
    
    public let name: String
    public let author: String?
    
    public let description: String?
    
    public let cover: Cover?
    public let genres: [String]
    
    public let addedAt: Date
    public let released: String?
    
    init(id: String, libraryID: String, type: ItemType, name: String, author: String?, description: String?, cover: Cover?, genres: [String], addedAt: Date, released: String?) {
        self.id = id
        self.libraryID = libraryID
        self.type = type
        self.name = name
        self.author = author
        self.description = description
        self.cover = cover
        self.genres = genres
        self.addedAt = addedAt
        self.released = released
    }
    
    public enum ItemType: Identifiable, Hashable, Codable {
        case audiobook
        case author
        case series
        case podcast
        case episode
        
        public static func parse(_ value: String) -> Self? {
            if value == "audiobook" {
                return .audiobook
            } else if value == "author" {
                return .author
            } else if value == "series" {
                return .series
            } else if value == "podcast" {
                return .podcast
            } else if value == "episode" {
                return .episode
            }
            
            return nil
        }
        
        public var id: Self {
            self
        }
        
        public var value: String {
            switch self {
            case .audiobook:
                "audiobook"
            case .author:
                "author"
            case .series:
                "series"
            case .podcast:
                "podcast"
            case .episode:
                "episode"
            }
        }
    }
}

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.sortName < rhs.sortName
    }
}

public extension Item {
    var sortName: String {
        get {
            var sortName = name.lowercased()
            
            if sortName.starts(with: "a ") {
                sortName = String(sortName.dropFirst(2))
            }
            if sortName.starts(with: "the ") {
                sortName = String(sortName.dropFirst(4))
            }
            
            return sortName
        }
    }
    
    var authors: [String]? {
        guard let author else {
            return nil
        }
        
        return author.components(separatedBy: ", ").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    var identifiers: (itemID: String, episodeID: String?) {
        if let episode = self as? Episode {
            return (itemID: episode.podcastId, episodeID: episode.id)
        }
        
        return (itemID: id, episodeID: nil)
    }
}
