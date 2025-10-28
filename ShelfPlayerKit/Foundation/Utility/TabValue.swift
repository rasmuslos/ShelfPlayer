//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI

// adding equatable crashes the app...
public indirect enum TabValue: Identifiable, Hashable, Codable, Defaults.Serializable, Sendable {
    case audiobookHome(Library)
    
    case audiobookSeries(Library)
    case audiobookAuthors(Library)
    case audiobookNarrators(Library)
    case audiobookBookmarks(Library)
    case audiobookCollections(Library)
    
    case audiobookLibrary(Library)
    
    case podcastHome(Library)
    case podcastLatest(Library)
    case podcastLibrary(Library)
    
    case playlists(Library)
    case search(Library)
    
    case custom(TabValue)
    
    public var id: String {
        switch self {
        case .audiobookHome(let library):
            "audiobookHome_\(library.id)_\(library.connectionID)"
        case .audiobookSeries(let library):
            "audiobookSeries_\(library.id)_\(library.connectionID)"
        case .audiobookAuthors(let library):
            "audiobookAuthors_\(library.id)_\(library.connectionID)"
        case .audiobookNarrators(let library):
            "audiobookNarrators_\(library.id)_\(library.connectionID)"
        case .audiobookBookmarks(let library):
            "audiobookBookmarks_\(library.id)_\(library.connectionID)"
        case .audiobookCollections(let library):
            "audiobookCollections_\(library.id)_\(library.connectionID)"
        case .audiobookLibrary(let library):
            "audiobookLibrary_\(library.id)_\(library.connectionID)"
        case .podcastHome(let library):
            "podcastHome_\(library.id)_\(library.connectionID)"
        case .podcastLatest(let library):
            "podcastLatest_\(library.id)_\(library.connectionID)"
        case .podcastLibrary(let library):
            "podcastLibrary_\(library.id)_\(library.connectionID)"
        case .playlists(let library):
            "playlists_\(library.id)_\(library.connectionID)"
        case .search(let library):
            "search_\(library.id)_\(library.connectionID)"
        case .custom(let tabValue):
            "custom_\(tabValue.id)"
        }
    }
    
    public var library: Library {
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
            case .search(let library):
                library
                
            case .custom(let tabValue):
                tabValue.library
        }
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
        && lhs.library == rhs.library
    }
}
