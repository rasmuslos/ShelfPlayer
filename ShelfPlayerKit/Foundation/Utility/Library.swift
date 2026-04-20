//
//  Library.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public struct Library: Identifiable, Hashable, Codable, Sendable, Equatable, Comparable {
    public let id: LibraryIdentifier

    public let index: Int
    public let name: String

    public init(id libraryID: String, connectionID: ItemIdentifier.ConnectionID, name: String, type typeString: String, index: Int) {
        let type: LibraryMediaType

        switch typeString {
        case "book":
            type = .audiobooks
        case "podcast":
            type = .podcasts
        default:
            fatalError("Unsupported library type: \(typeString)")
        }

        id = .init(type: type, libraryID: libraryID, connectionID: connectionID)

        self.name = name
        self.index = index
    }

    public init(id libraryID: String, connectionID: ItemIdentifier.ConnectionID, name: String, type: LibraryMediaType, index: Int) {
        id = .init(type: type, libraryID: libraryID, connectionID: connectionID)
        self.name = name
        self.index = index
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    public static func < (lhs: Library, rhs: Library) -> Bool {
        lhs.index < rhs.index
    }
}

public struct LibraryIdentifier: Identifiable, Hashable, Codable, Sendable, Equatable {
    public let type: LibraryMediaType

    public let libraryID: ItemIdentifier.LibraryID
    public let connectionID: ItemIdentifier.ConnectionID

    public var id: String {
        "\(type.rawValue.description)_\(libraryID)_\(connectionID)"
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.connectionID == rhs.connectionID
    }

    public static func convertItemIdentifierToLibraryIdentifier(_ itemID: ItemIdentifier) -> LibraryIdentifier {
        let type: LibraryMediaType

        switch itemID.type {
        case .episode, .podcast: type = .podcasts
        case .audiobook, .author, .narrator, .series, .collection: type = .audiobooks
        case .playlist: type = .podcasts
        }

        return LibraryIdentifier(type: type, libraryID: itemID.libraryID, connectionID: itemID.connectionID)
    }
}

public enum LibraryMediaType: Int, Hashable, Codable, Sendable {
    case audiobooks = 1
    case podcasts = 2
}
