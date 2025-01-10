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
    var isLibrary: Bool {
        switch self {
        case .audiobookLibrary, .podcastLibrary:
            true
        case .audiobookHome, .audiobookSeries, .audiobookAuthors, .podcastHome, .podcastLatest, .search:
            false
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
            "house.fill"
        case .audiobookSeries:
            "rectangle.grid.2x2.fill"
        case .audiobookAuthors:
            "person.2.fill"
        case .audiobookLibrary:
            "books.vertical.fill"
            
        case .podcastHome:
            "house.fill"
        case .podcastLatest:
            "calendar.badge.clock"
        case .podcastLibrary:
            "square.split.2x2.fill"
            
        case .search:
            "magnifyingglass"
        }
    }
    
    @ViewBuilder @MainActor
    func content(libraryPath: Binding<NavigationPath>) -> some View {
        Group {
            switch self {
            case .audiobookHome:
                NavigationStack {
                    AudiobookHomePanel()
                        .modifier(Navigation.DestinationModifier())
                }
            case .audiobookSeries:
                NavigationStack {
                    AudiobookSeriesPanel()
                        .modifier(Navigation.DestinationModifier())
                }
            case .audiobookAuthors:
                NavigationStack {
                    AudiobookAuthorsPanel()
                        .modifier(Navigation.DestinationModifier())
                }
                
            case .podcastHome:
                NavigationStack {
                    PodcastHomePanel()
                        .modifier(Navigation.DestinationModifier())
                }
            case .podcastLatest:
                NavigationStack {
                    PodcastLatestPanel()
                        .modifier(Navigation.DestinationModifier())
                }
                
            case .audiobookLibrary:
                NavigationStack(path: libraryPath) {
                    AudiobookLibraryPanel()
                        .modifier(Navigation.DestinationModifier())
                }
            case .podcastLibrary:
                NavigationStack(path: libraryPath) {
                    PodcastLibraryPanel()
                        .modifier(Navigation.DestinationModifier())
                }
                
            case .search:
                NavigationStack {
                    SearchView()
                        .modifier(Navigation.DestinationModifier())
                }
            }
        }
        .environment(\.library, library)
        // .modifier(NowPlaying.RegularModifier())
        // .modifier(NowPlaying.BackgroundModifier())
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
