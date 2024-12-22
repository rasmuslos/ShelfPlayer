//
//  ItemIdentifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

/**
 ShelfPlayer Item Identifier
 
 Identifier comprised of multiple others provided by Audiobookshelf. Current and only version: `1`
 
 ### Format
 `VERSION::TYPE::SERVER_ID::LIBRARY_ID::PRIMARY_ID(::GROUPING_ID)`
 */
public final class ItemIdentifier: Codable {
    public typealias PrimaryID = String
    public typealias GroupingID = String?
    
    public typealias LibraryID = String
    public typealias ServerID = String
    
    public let primaryID: PrimaryID
    public let groupingID: GroupingID
    
    public let _libraryID: LibraryID!
    public let _serverID: ServerID!
    
    public let type: ItemType
    
    public init(primaryID: PrimaryID, groupingID: GroupingID, libraryID: LibraryID, serverID: ServerID, type: ItemType) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        _libraryID = libraryID
        _serverID = serverID
        
        self.type = type
    }
    
    /// Convenience initializer for an audiobook
    public init(primaryID: String) {
        self.primaryID = primaryID
        self.groupingID = nil
        
        _libraryID = nil
        _serverID = nil
        
        type = .audiobook
    }
    /// Convenience initializer for an episode
    public init(primaryID: String, groupingID: String?) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        _libraryID = nil
        _serverID = nil
        
        type = .episode
    }
    
    public init(string identifier: String) {
        let parts = identifier.split(separator: "::")
        
        switch parts[0] {
        case "1":
            type = ItemType(rawValue: String(parts[1]))!
            
            let libraryID = String(parts[2])
            let serverID = String(parts[3])
            
            if libraryID == "_" {
                _libraryID = nil
            } else {
                _libraryID = libraryID
            }
            if serverID == "_" {
                _serverID = nil
            } else {
                _serverID = serverID
            }
            
            primaryID = String(parts[4])
            
            if parts.count == 6 {
                groupingID = String(parts[5])
            } else {
                groupingID = nil
            }
        default:
            fatalError("Unknown identifier format: \(identifier)")
        }
    }
    
    public var libraryID: LibraryID {
        _libraryID ?? ""
    }
    public var serverID: ServerID {
        _serverID ?? ""
    }
    
    var shallow: Bool {
        _libraryID == nil || _serverID == nil
    }
    
    enum ParseError: Error {
        case invalidVersion
    }
}

extension ItemIdentifier: Sendable {}
extension ItemIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(primaryID)
        hasher.combine(groupingID)
    }
}
extension ItemIdentifier: Equatable {
    public static func ==(lhs: ItemIdentifier, rhs: ItemIdentifier) -> Bool {
        lhs.primaryID == rhs.primaryID && lhs.groupingID == rhs.groupingID
    }
}
extension ItemIdentifier: Identifiable {
    public var id: String {
        description
    }
}
extension ItemIdentifier: CustomStringConvertible {
    public var description: String {
        let base = "1::\(type)::\(_serverID ?? "_")::\(_libraryID ?? "_")::\(primaryID)"
        
        if let groupingID {
            return base + "::\(groupingID)"
        }
        
        return base
    }
}

public extension ItemIdentifier {
    enum ItemType: String, Codable, Sendable, CustomStringConvertible {
        case audiobook = "audiobook"
        case author = "author"
        case series = "series"
        case podcast = "podcast"
        case episode = "episode"
        
        public var description: String {
            rawValue
        }
    }
}
