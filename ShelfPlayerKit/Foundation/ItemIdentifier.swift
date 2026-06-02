//
//  ItemIdentifier.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation
import OSLog

/// ShelfPlayer Item Identifier
///
/// Identifier comprised of multiple others provided by Audiobookshelf. Current and only version: `1`
///
/// ### Format
/// `VERSION::TYPE::SERVER_ID::LIBRARY_ID::PRIMARY_ID(::GROUPING_ID)`
public final class ItemIdentifier: NSObject {
    public typealias PrimaryID = String
    public typealias GroupingID = String

    public typealias LibraryID = String
    public typealias ConnectionID = String

    public let primaryID: PrimaryID
    public let groupingID: GroupingID?

    public let libraryID: LibraryID
    public let connectionID: ConnectionID

    public let type: ItemType

    private static let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "ItemIdentifier")

    public init(primaryID: PrimaryID, groupingID: GroupingID?, libraryID: LibraryID, connectionID: ConnectionID, type: ItemType) {
        self.primaryID = primaryID
        self.groupingID = groupingID

        self.libraryID = libraryID
        self.connectionID = connectionID

        self.type = type
    }

    public init(string identifier: String) {
        let parts = identifier.split(separator: "::")

        if (parts.count == 5 || parts.count == 6), parts[0] == "1", let type = ItemType(rawValue: String(parts[1])) {
            self.type = type

            connectionID = String(parts[2])
            libraryID = String(parts[3])
            primaryID = String(parts[4])
            groupingID = parts.count == 6 ? String(parts[5]) : nil
        } else {
            // A malformed identifier must not crash the app — it can reach us
            // from corrupted persistence, a stale URL, or legacy migration data.
            // Fall back to an inert identifier that resolves to nothing.
            Self.logger.fault("Unparseable item identifier, falling back to inert id: \(identifier, privacy: .public)")

            type = .audiobook
            connectionID = ""
            libraryID = ""
            primaryID = identifier
            groupingID = nil
        }
    }

    public static func convertEpisodeIdentifierToPodcastIdentifier(_ episodeID: ItemIdentifier) -> ItemIdentifier {
        ItemIdentifier(primaryID: episodeID.groupingID!, groupingID: nil, libraryID: episodeID.libraryID, connectionID: episodeID.connectionID, type: .podcast)
    }

    public static func isValid(_ identifier: String) -> Bool {
        guard identifier.starts(with: "1::") else {
            return false
        }

        let parts = identifier.split(separator: "::")

        guard parts.count == 5 || parts.count == 6 else {
            return false
        }

        return true
    }

    public var isPlayable: Bool {
        type == .audiobook || type == .episode
    }

    public var isCollection: Bool {
        type == .collection || type == .playlist
    }

    public override var description: String {
        let base = "1::\(type)::\(connectionID)::\(libraryID)::\(primaryID)"

        if let groupingID {
            return base + "::\(groupingID)"
        }

        return base
    }
}

// MARK: - Conformances

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

public extension ItemIdentifier {
    override var hash: Int {
        var hasher = Hasher()

        hasher.combine(primaryID)
        hasher.combine(groupingID)
        hasher.combine(libraryID)
        hasher.combine(connectionID)

        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ItemIdentifier else {
            return false
        }

        return primaryID == rhs.primaryID && groupingID == rhs.groupingID && libraryID == rhs.libraryID && connectionID == rhs.connectionID
    }

    func isEqual(primaryID: PrimaryID, groupingID: GroupingID?, connectionID: ConnectionID) -> Bool {
        self.primaryID == primaryID && self.groupingID == groupingID && self.connectionID == connectionID
    }

    func matchesItemUpdate(connectionID: ConnectionID, primaryID: PrimaryID, groupingID: GroupingID?) -> Bool {
        guard self.connectionID == connectionID else {
            return false
        }

        if self.primaryID == primaryID && self.groupingID == groupingID {
            return true
        }

        if groupingID == nil && self.groupingID == primaryID {
            return true
        }

        return false
    }
}

extension ItemIdentifier: Sendable {}

extension ItemIdentifier: Identifiable {
    public var id: String {
        description
    }
}

extension ItemIdentifier: LosslessStringConvertible {
    public convenience init(_ description: String) {
        self.init(string: description)
    }
}

// MARK: - Item Type

public extension ItemIdentifier {
    enum ItemType: String, Codable, Sendable, LosslessStringConvertible, Hashable {
        case audiobook = "audiobook"
        case author = "author"
        case narrator = "narrator"
        case series = "series"

        case podcast = "podcast"
        case episode = "episode"
        case channel = "channel"

        case collection = "collection"
        case playlist = "playlist"

        public init?(_ description: String) {
            self.init(rawValue: description)
        }

        public var description: String {
            rawValue
        }
    }
}

// MARK: - Connection ID

public extension ItemIdentifier.ConnectionID {
    var urlSafe: String {
        replacingOccurrences(of: "/", with: "_")
    }
}
