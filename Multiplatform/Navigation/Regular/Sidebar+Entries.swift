//
//  Sidebar+Entries.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import Foundation
import Defaults
import SwiftUI
import SPBase

extension SidebarView {
    struct Selection: Codable, Hashable, _DefaultsSerializable {
        let libraryId: String
        let section: LibrarySection
    }
    
    enum LibrarySection: Codable, Hashable, _DefaultsSerializable {
        case podcastListenNow
        case audiobookListenNow
        case latest
        case series
        case podcastLibrary
        case audiobookLibrary
        case authors
        case search
    }
}

extension SidebarView.LibrarySection {
    var label: LocalizedStringKey {
        switch self {
            case .audiobookListenNow, .podcastListenNow:
                "section.listenNow"
            case .latest:
                "section.latest"
            case .series:
                "section.series"
            case .audiobookLibrary, .podcastLibrary:
                "section.library"
            case .authors:
                "section.authors"
            case .search:
                "section.search"
        }
    }
    
    var icon: String {
        switch self {
            case .podcastListenNow:
                "waveform"
            case .audiobookListenNow:
                "bookmark.fill"
            case .latest:
                "clock"
            case .series:
                "books.vertical.fill"
            case .podcastLibrary:
                "tray.fill"
            case .audiobookLibrary:
                "book.fill"
            case .authors:
                "person.fill"
            case .search:
                "magnifyingglass"
        }
    }
    
    var content: some View {
        Group {
            switch self {
                case .podcastListenNow:
                    PodcastListenNowView()
                case .audiobookListenNow:
                    AudiobookListenNowView()
                case .latest:
                    PodcastLatestView()
                case .series:
                    AudiobookSeriesView()
                case .podcastLibrary:
                    PodcastLibraryView()
                case .audiobookLibrary:
                    AudiobookLibraryView()
                case .authors:
                    AuthorsView()
                case .search:
                    SearchView()
            }
        }
    }
    
    static func filtered(libraryType: Library.MediaType) -> [Self] {
        switch libraryType {
            case .audiobooks:
                return [.audiobookListenNow, .series, authors, .audiobookLibrary, .search]
            case .podcasts:
                return [.podcastListenNow, .latest, .podcastLibrary, .search]
        }
    }
}
