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
public final class ItemIdentifier {
    public typealias PrimaryID = String
    public typealias GroupingID = String
    
    public typealias LibraryID = String
    public typealias ConnectionID = String
    
    public let primaryID: PrimaryID
    public let groupingID: GroupingID?
    
    public let libraryID: LibraryID
    public let connectionID: ConnectionID
    
    public let type: ItemType
    
    public init(primaryID: PrimaryID, groupingID: GroupingID?, libraryID: LibraryID, connectionID: ConnectionID, type: ItemType) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        self.libraryID = libraryID
        self.connectionID = connectionID
        
        self.type = type
    }
    
    public init(string identifier: String) {
        let parts = identifier.split(separator: "::")
        
        switch parts[0] {
        case "1":
            type = ItemType(rawValue: String(parts[1]))!
            
            libraryID = String(parts[2])
            connectionID = String(parts[3])
            
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
    
    enum ParseError: Error {
        case invalidVersion
    }
}

extension ItemIdentifier: Codable {}

extension ItemIdentifier: NSSecureCoding {
    public func encode(with coder: NSCoder) {
        coder.encode(primaryID as NSString, forKey: "primaryID")
        coder.encode(groupingID as? NSString, forKey: "groupingID")
        coder.encode(libraryID as NSString, forKey: "libraryID")
        coder.encode(connectionID as NSString, forKey: "connectionID")
        coder.encode(type.rawValue as NSString, forKey: "type")
    }
    
    public convenience init?(coder: NSCoder) {
        guard let primaryID = coder.decodeObject(of: NSString.self, forKey: "primaryID") as? String,
              let groupingID = coder.decodeObject(of: NSString.self, forKey: "groupingID") as? String,
              let libraryID = coder.decodeObject(of: NSString.self, forKey: "libraryID") as? String,
              let connectionID = coder.decodeObject(of: NSString.self, forKey: "connectionID") as? String,
              let typeString = coder.decodeObject(of: NSString.self, forKey: "type") as? String else { return nil }
        
        guard let type = ItemIdentifier.ItemType(rawValue: typeString) else { return nil }
        
        self.init(primaryID: primaryID, groupingID: groupingID, libraryID: libraryID, connectionID: connectionID, type: type)
    }
    
    public static var supportsSecureCoding: Bool {
        true
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
extension ItemIdentifier: LosslessStringConvertible {
    public convenience init(_ description: String) {
        self.init(string: description)
    }
    
    public var description: String {
        let base = "1::\(type)::\(connectionID)::\(libraryID)::\(primaryID)"
        
        if let groupingID {
            return base + "::\(groupingID)"
        }
        
        return base
    }
}

public extension ItemIdentifier {
    enum ItemType: String, Codable, Sendable, LosslessStringConvertible {
        case audiobook = "audiobook"
        case author = "author"
        case series = "series"
        case podcast = "podcast"
        case episode = "episode"
        
        public init?(_ description: String) {
            self.init(rawValue: description)
        }
        
        public var description: String {
            rawValue
        }
    }
}
