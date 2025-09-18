//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI

public indirect enum TabValue: Identifiable, Hashable, Codable, Defaults.Serializable {
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
    
    public var id: Self {
        self
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
}
