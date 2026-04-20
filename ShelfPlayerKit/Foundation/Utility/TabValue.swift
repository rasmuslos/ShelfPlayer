//
//  TabValue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI

public indirect enum TabValue: Identifiable, Hashable, Codable, Sendable {
    case audiobookHome(LibraryIdentifier)

    case audiobookSeries(LibraryIdentifier)
    case audiobookAuthors(LibraryIdentifier)
    case audiobookNarrators(LibraryIdentifier)
    case audiobookBookmarks(LibraryIdentifier)
    case audiobookCollections(LibraryIdentifier)
    case audiobookGenres(LibraryIdentifier)
    case audiobookTags(LibraryIdentifier)

    case audiobookLibrary(LibraryIdentifier)

    case podcastHome(LibraryIdentifier)
    case podcastLatest(LibraryIdentifier)
    case podcastLibrary(LibraryIdentifier)

    case playlists(LibraryIdentifier)
    case collection(ItemCollection, LibraryIdentifier)

    case downloaded(LibraryIdentifier)

    case custom(TabValue, String)

    case search
    case loading

    public var id: String {
        switch self {
        case .audiobookHome(let library):
            "audiobookHome_\(library.id)"
        case .audiobookSeries(let library):
            "audiobookSeries_\(library.id)"
        case .audiobookAuthors(let library):
            "audiobookAuthors_\(library.id)"
        case .audiobookNarrators(let library):
            "audiobookNarrators_\(library.id)"
        case .audiobookBookmarks(let library):
            "audiobookBookmarks_\(library.id)"
        case .audiobookCollections(let library):
            "audiobookCollections_\(library.id)"
        case .audiobookGenres(let library):
            "audiobookGenres_\(library.id)"
        case .audiobookTags(let library):
            "audiobookTags_\(library.id)"
        case .audiobookLibrary(let library):
            "audiobookLibrary_\(library.id)"
        case .podcastHome(let library):
            "podcastHome_\(library.id)"
        case .podcastLatest(let library):
            "podcastLatest_\(library.id)"
        case .podcastLibrary(let library):
            "podcastLibrary_\(library.id)"

        case .playlists(let library):
            "playlists_\(library.id)"
        case .collection(let collection, let library):
            "collection_\(collection.id)_\(library.id)"

        case .downloaded(let libraryID):
            "downloaded_\(libraryID.id)"

        case .custom(let tabValue, _):
            "custom_\(tabValue.id)"

        case .search:
            "search"
        case .loading:
            "loading"
        }
    }

    public var libraryID: LibraryIdentifier? {
        switch self {
        case .audiobookHome(let library),
             .audiobookSeries(let library),
             .audiobookAuthors(let library),
             .audiobookNarrators(let library),
             .audiobookBookmarks(let library),
             .audiobookCollections(let library),
             .audiobookGenres(let library),
             .audiobookTags(let library),
             .audiobookLibrary(let library),
             .podcastHome(let library),
             .podcastLatest(let library),
             .podcastLibrary(let library),
             .playlists(let library),
             .downloaded(let library):
            library

        case .collection(_, let library):
            library

        case .custom(let tabValue, _):
            tabValue.libraryID

        case .search, .loading:
            nil
        }
    }

    public var isEligibleForSaving: Bool {
        switch self {
        case .loading: false
        default: true
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.libraryID == rhs.libraryID
    }
}
