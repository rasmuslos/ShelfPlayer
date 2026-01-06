//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI

// adding equatable crashes the app...
public indirect enum TabValue: Identifiable, Hashable, Codable, Defaults.Serializable, Sendable {
    case audiobookHome(LibraryIdentifier)
    
    case audiobookSeries(LibraryIdentifier)
    case audiobookAuthors(LibraryIdentifier)
    case audiobookNarrators(LibraryIdentifier)
    case audiobookBookmarks(LibraryIdentifier)
    case audiobookCollections(LibraryIdentifier)
    
    case audiobookLibrary(LibraryIdentifier)
    
    case podcastHome(LibraryIdentifier)
    case podcastLatest(LibraryIdentifier)
    case podcastLibrary(LibraryIdentifier)
    
    case playlists(LibraryIdentifier)
    case collection(ItemCollection, LibraryIdentifier)
    
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
            case .audiobookHome(let library):
                library
            case .audiobookSeries(let library):
                library
            case .audiobookAuthors(let library):
                library
            case .audiobookNarrators(let library):
                library
            case .audiobookBookmarks(let library):
                library
            case .audiobookCollections(let library):
                library
            case .audiobookLibrary(let library):
                library
            case .podcastHome(let library):
                library
            case .podcastLatest(let library):
                library
            case .podcastLibrary(let library):
                library
                
            case .playlists(let library):
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
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.libraryID == rhs.libraryID
    }
}
