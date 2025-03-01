//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

enum TabValue: Identifiable, Hashable, Codable, Defaults.Serializable {
    case audiobookHome(Library)
    case audiobookSeries(Library)
    case audiobookAuthors(Library)
    case audiobookLibrary(Library)
    case audiobookSearch(Library)
    
    case podcastHome(Library)
    case podcastLatest(Library)
    case podcastLibrary(Library)
    
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
        case .audiobookSearch(let library):
            library
        case .podcastHome(let library):
            library
        case .podcastLatest(let library):
            library
        case .podcastLibrary(let library):
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
        case .audiobookSearch:
            "panel.search"
            
        case .podcastHome:
            "panel.home"
        case .podcastLatest:
            "panel.latest"
        case .podcastLibrary:
            "panel.library"
        }
    }
    
    var image: String {
        switch self {
        case .audiobookHome:
            "house.fill"
        case .audiobookSeries:
            "rectangle.grid.2x2.fill"
        case .audiobookAuthors:
            "person.2.fill"
        case .audiobookLibrary:
            "books.vertical.fill"
        case .audiobookSearch:
            "magnifyingglass"
            
        case .podcastHome:
            "house.fill"
        case .podcastLatest:
            "calendar.badge.clock"
        case .podcastLibrary:
            "square.split.2x2.fill"
        }
    }
    
    @ViewBuilder @MainActor
    var content: some View {
        NavigationStackWrapper(tab: self) {
            switch self {
            case .audiobookHome:
                AudiobookHomePanel()
            case .audiobookSeries:
                AudiobookSeriesPanel()
            case .audiobookAuthors:
                AudiobookAuthorsPanel()
            case .podcastLibrary:
                PodcastLibraryPanel()
            case .audiobookSearch:
                SearchView()
                
            case .podcastHome:
                PodcastHomePanel()
            case .podcastLatest:
                PodcastLatestPanel()
            case .audiobookLibrary:
                AudiobookLibraryPanel()
            }
        }
    }
}

internal extension TabValue {
    static func tabs(for library: Library) -> [TabValue] {
        switch library.type {
        case .audiobooks:
            [.audiobookHome(library), .audiobookSeries(library), .audiobookAuthors(library), .audiobookLibrary(library), .audiobookSearch(library)]
        case .podcasts:
            [.podcastHome(library), .podcastLatest(library), .podcastLibrary(library)]
        default:
            []
        }
    }
}
