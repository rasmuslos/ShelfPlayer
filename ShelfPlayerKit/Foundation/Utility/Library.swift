//
//  Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public struct Library {
    public let id: String
    public let connectionID: ItemIdentifier.ConnectionID
    
    public let name: String
    
    public let type: MediaType
    public let index: Int
    
    public init(id: String, connectionID: ItemIdentifier.ConnectionID, name: String, type: String, index: Int) {
        self.id = id
        self.connectionID = connectionID
        
        self.name = name
        
        switch type {
        case "book":
            self.type = .audiobooks
        case "podcast":
            self.type = .podcasts
        default:
            fatalError("Unsupported library type: \(type)")
        }

        self.index = index
    }
    
    public init(id: String, connectionID: ItemIdentifier.ConnectionID, name: String, type: MediaType, index: Int) {
        self.id = id
        self.connectionID = connectionID
        
        self.name = name
        
        self.type = type
        self.index = index
    }
    
    public enum MediaType: Int, Hashable, Codable, Sendable, Defaults.Serializable {
        case audiobooks = 1
        case podcasts = 2
    }
}

extension Library: Codable {}
extension Library: Hashable {}
extension Library: Sendable {}
extension Library: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.connectionID == rhs.connectionID
    }
}
extension Library: Comparable {
    public static func <(lhs: Library, rhs: Library) -> Bool {
        lhs.index < rhs.index
    }
}
extension Library: Identifiable {}
extension Library: Defaults.Serializable {}
