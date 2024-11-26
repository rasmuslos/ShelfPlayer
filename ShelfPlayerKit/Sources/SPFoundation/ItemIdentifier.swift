//
//  ItemIdentifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

public class ItemIdentifier: Codable {
    public let primaryID: String
    public let groupingID: String?
    public let libraryID: String!
    
    public let type: ItemType
    
    public init(string identifier: String) throws {
        let parts = identifier.split(separator: "::")
        
        guard parts[0] == "1" else {
            throw ParseError.invalidVersion
        }
        
        type = ItemType.parse(String(parts[1]))!
        let libraryID = String(parts[2])
        
        if libraryID == "_" {
            self.libraryID = nil
        } else {
            self.libraryID = libraryID
        }
        
        primaryID = String(parts[3])
        
        if parts.count == 5 {
            episodeID = String(parts[4])
        } else {
            episodeID = nil
        }
    }
    
    public convenience init(itemID: String, episodeID: String?) {
        self.init(itemID: itemID, episodeID: episodeID, libraryID: nil, type: episodeID != nil ? .episode : .audiobook)
    }
    public init(itemID: String, episodeID: String?, libraryID: String?, type: ItemType) {
        self.primaryID = itemID
        self.episodeID = episodeID
        self.type = type
        
        if libraryID == "_" {
            self.libraryID = nil
        } else {
            self.libraryID = libraryID
        }
    }
    
    enum ParseError: Error {
        case invalidVersion
    }
}

extension ItemIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(primaryID)
        hasher.combine(primaryID)
    }
}
extension ItemIdentifier: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.primaryID == rhs.primaryID && lhs.episodeID == rhs.episodeID
    }
    
    public func equals(itemID: String, episodeID: String?) -> Bool {
        self.primaryID == itemID && self.episodeID == episodeID
    }
}
extension ItemIdentifier: Identifiable {
    public var id: String {
        description
    }
}
extension ItemIdentifier: CustomStringConvertible {
    public var description: String {
        var identifier = "1::\(type)::\(libraryID ?? "_")::\(primaryID)"
        
        if let episodeID {
            identifier += "::\(episodeID)"
        }
        
        return identifier
    }
}

public extension ItemIdentifier {
    enum ItemType: String, Identifiable, Hashable, Codable, CustomStringConvertible {
        case audiobook
        case author
        case series
        case podcast
        case episode
        
        public var id: String {
            description
        }
        
        public var description: String {
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
    }
}

public extension ItemIdentifier {
    struct AudiobookIdentifier: ItemIdentifier {}
}
