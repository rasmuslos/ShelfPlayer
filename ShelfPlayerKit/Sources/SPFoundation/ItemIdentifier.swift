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
    public typealias GroupingID = String
    
    public typealias LibraryID = String
    public typealias ConnectionID = String
    
    public let primaryID: PrimaryID
    public let groupingID: GroupingID?
    
    public let _libraryID: LibraryID!
    public let _connectionID: ConnectionID!
    
    public let type: ItemType
    
    public init(primaryID: PrimaryID, groupingID: GroupingID?, libraryID: LibraryID, connectionID: ConnectionID, type: ItemType) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        _libraryID = libraryID
        _connectionID = connectionID
        
        self.type = type
    }
    
    /// Convenience initializer for an audiobook
    public init(primaryID: String) {
        self.primaryID = primaryID
        self.groupingID = nil
        
        _libraryID = nil
        _connectionID = nil
        
        type = .audiobook
    }
    /// Convenience initializer for an episode
    public init(primaryID: String, groupingID: String?) {
        self.primaryID = primaryID
        self.groupingID = groupingID
        
        _libraryID = nil
        _connectionID = nil
        
        type = .episode
    }
    
    public init(string identifier: String) {
        let parts = identifier.split(separator: "::")
        
        switch parts[0] {
        case "1":
            type = ItemType(rawValue: String(parts[1]))!
            
            let libraryID = String(parts[2])
            let connectionID = String(parts[3])
            
            if libraryID == "_" {
                _libraryID = nil
            } else {
                _libraryID = libraryID
            }
            if connectionID == "_" {
                _connectionID = nil
            } else {
                _connectionID = connectionID
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
    public var connectionID: ConnectionID {
        _connectionID ?? ""
    }
    
    var shallow: Bool {
        _libraryID == nil || _connectionID == nil
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
extension ItemIdentifier: LosslessStringConvertible {
    public convenience init(_ description: String) {
        self.init(string: description)
    }
    
    public var description: String {
        let base = "1::\(type)::\(_connectionID ?? "_")::\(_libraryID ?? "_")::\(primaryID)"
        
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

@objc(NSAttributedStringTransformer)
public class ItemIdentifierTransformer: NSSecureUnarchiveFromDataTransformer {
    public override class func allowsReverseTransformation() -> Bool {
        true
    }

    public override class var allowedTopLevelClasses: [AnyClass] {
        [ItemIdentifier.self]
    }

    public override class func transformedValueClass() -> AnyClass {
        ItemIdentifier.self
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let id = value as? ItemIdentifier, let data = id.description.data(using: .utf8) {
            NSData(data: data)
        } else {
            nil
        }
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        if let data = value as? NSData, let string = String(data: data as Data, encoding: .utf8) {
            ItemIdentifier(string)
        } else {
            nil
        }
    }
}

public extension NSValueTransformerName {
    static let itemIdentifierTransformer = NSValueTransformerName(rawValue: "ItemIdentifierTransformer")
}
