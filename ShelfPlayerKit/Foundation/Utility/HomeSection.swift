//
//  HomeSection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 19.04.26.
//

import Foundation

public enum HomeSectionKind: Codable, Hashable, Sendable {
    // Server-driven rows (from ABSClient.home(for:)).
    // The associated `id` matches `HomeRow.id` returned by the server.
    case serverRow(id: String)

    // Client-derived sections.
    case listenNow
    case upNext
    /// Next unplayed episode per recently-played podcast in the current scope.
    case nextUpPodcasts
    case downloadedAudiobooks
    case downloadedEpisodes
    case bookmarks
    /// Renders the items of a specific user collection as a home row. The
    /// associated string is the collection's `ItemIdentifier.description`.
    case collection(itemID: String)
    /// Renders the items of a specific user playlist as a home row. The
    /// associated string is the playlist's `ItemIdentifier.description`.
    case playlist(itemID: String)

    public var stableID: String {
        switch self {
        case .serverRow(let id): "server::\(id)"
        case .listenNow: "client::listenNow"
        case .upNext: "client::upNext"
        case .nextUpPodcasts: "client::nextUpPodcasts"
        case .downloadedAudiobooks: "client::downloadedAudiobooks"
        case .downloadedEpisodes: "client::downloadedEpisodes"
        case .bookmarks: "client::bookmarks"
        case .collection(let itemID): "client::collection::\(itemID)"
        case .playlist(let itemID): "client::playlist::\(itemID)"
        }
    }

    public var isClientDerived: Bool {
        if case .serverRow = self { false } else { true }
    }
}

public struct HomeSection: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var kind: HomeSectionKind

    /// When non-nil, the section is resolved against this library instead of
    /// the enclosing scope's library. Used by the multi-library panel to
    /// aggregate content across libraries.
    public var libraryID: LibraryIdentifier?

    public var isHidden: Bool

    public init(id: UUID = UUID(),
                kind: HomeSectionKind,
                libraryID: LibraryIdentifier? = nil,
                isHidden: Bool = false) {
        self.id = id
        self.kind = kind
        self.libraryID = libraryID
        self.isHidden = isHidden
    }
}

public enum HomeScope: Hashable, Sendable {
    /// The start page of a specific library.
    case library(LibraryIdentifier)
    /// The multi-library start page — aggregates rows across libraries.
    case multiLibrary

    public var key: String {
        switch self {
        case .library(let libraryID): "library::\(libraryID.id)"
        case .multiLibrary: "multiLibrary"
        }
    }

    /// The library used to resolve a section when the section itself does not
    /// carry an override. The multi-library scope has none.
    public var implicitLibraryID: LibraryIdentifier? {
        switch self {
        case .library(let libraryID): libraryID
        case .multiLibrary: nil
        }
    }
}
