//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal enum TabValue: Identifiable, Hashable {
    case audiobookHome(Library)
    case audiobookSeries(Library)
    case audiobookAuthors(Library)
    case audiobookLibrary(Library)
    
    case podcastHome(Library)
    case podcastLatest(Library)
    case podcastLibrary(Library)
    
    case search(Library)
    
    var id: Self {
        self
    }
    
    var library: Library {
        switch self {
        case .audiobookHome(let library):
            library
        case .audiobookSeries(let library):
            library
        case .audiobookAuthors(let library):
            library
        case .audiobookLibrary(let library):
            library
        case .podcastHome(let library):
            library
        case .podcastLatest(let library):
            library
        case .podcastLibrary(let library):
            library
        case .search(let library):
            library
        }
    }
    
    var label: LocalizedStringKey {
        switch self {
        case .audiobookHome:
            "panel.home"
        case .audiobookSeries:
            "panel.series"
        case .audiobookAuthors:
            "panel.authors"
        case .audiobookLibrary:
            "panel.library"
            
        case .podcastHome:
            "panel.home"
        case .podcastLatest:
            "panel.latest"
        case .podcastLibrary:
            "panel.library"
            
        case .search:
            "panel.search"
        }
    }
    
    var image: String {
        switch self {
        case .audiobookHome:
            "play.house.fill"
        case .audiobookSeries:
            "rectangle.grid.3x2.fill"
        case .audiobookAuthors:
            "person.2.fill"
        case .audiobookLibrary:
            "books.vertical.fill"
            
        case .podcastHome:
            "music.note.house.fill"
        case .podcastLatest:
            "calendar.badge.clock"
        case .podcastLibrary:
            "square.split.2x2.fill"
            
        case .search:
            "magnifyingglass"
        }
    }
    
    @ViewBuilder
    var content: some View {
        NavigationStack {
            switch self {
            case .audiobookHome:
                AudiobookHomePanel()
            case .audiobookSeries:
                AudiobookSeriesPanel()
            case .audiobookAuthors:
                AudiobookAuthorsPanel()
            case .audiobookLibrary:
                AudiobookLibraryPanel()
                
            case .podcastHome:
                PodcastHomePanel()
            case .podcastLatest:
                PodcastLatestPanel()
            case .podcastLibrary:
                PodcastLibraryPanel()
                
            case .search:
                SearchView()
            }
        }
        .environment(\.library, library)
        .modifier(NowPlaying.CompactTabBarBackgroundModifier())
    }
}

internal extension TabValue {
    static func tabs(for library: Library) -> [TabValue] {
        switch library.type {
        case .audiobooks:
            [.audiobookHome(library), .audiobookSeries(library), .audiobookAuthors(library), .audiobookLibrary(library), .search(library)]
        case .podcasts:
            [.podcastHome(library), .podcastLatest(library), .podcastLibrary(library)]
        default:
            []
        }
    }
}
