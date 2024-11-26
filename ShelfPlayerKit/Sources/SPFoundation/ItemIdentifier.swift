//
//  ItemIdentifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

public final class ItemIdentifier: Codable {
    public let primaryID: String
    public let groupingID: String?
    
    public let libraryID: String?
    public let type: ItemType
    
    public init(primaryID: String, groupingID: String?, libraryID: String?, type: ItemType) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        if libraryID == "_" {
            self.libraryID = nil
        } else {
            self.libraryID = libraryID
        }
        
        self.type = type
    }
    
    public convenience init(primaryID: String, groupingID: String?) {
        self.init(primaryID: primaryID, groupingID: groupingID, libraryID: nil, type: groupingID != nil ? .episode : .audiobook)
    }
    
    public convenience init(string identifier: String) throws {
        let parts = identifier.split(separator: "::")
        
        var primaryID: String
        let groupingID: String?
        
        var libraryID: String?
        let type: ItemType
        
        switch parts[0] {
        case "1":
            type = ItemType(rawValue: String(parts[1]))!
            libraryID = String(parts[2])
            
            primaryID = String(parts[3])
            
            if parts.count == 5 {
                groupingID = primaryID
                primaryID = String(parts[4])
            } else {
                groupingID = nil
            }
        default:
            throw ParseError.invalidVersion
        }
        
        if libraryID == "_" {
            libraryID = nil
        }
        
        self.init(primaryID: primaryID, groupingID: groupingID, libraryID: libraryID, type: type)
    }
    
    public var _libraryID: String {
        libraryID ?? ""
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
        if let groupingID {
            "1::\(type)::\(self.libraryID ?? "_")::\(groupingID)::\(primaryID)"
        } else {
            "1::\(type)::\(self.libraryID ?? "_")::\(primaryID)"
        }
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
