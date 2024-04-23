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
        case search
    }
}

extension SidebarView.LibrarySection {
    var title: LocalizedStringKey {
        switch self {
            case .audiobookListenNow, .podcastListenNow:
                "section.listenNow"
            case .latest:
                "section.latest"
            case .series:
                "section.series"
            case .audiobookLibrary, .podcastLibrary:
                "section.library"
            case .search:
                "section.search"
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
                case .search:
                    SearchView()
            }
        }
    }
    
    static func filtered(libraryType: Library.MediaType) -> [Self] {
        switch libraryType {
            case .audiobooks:
                return [.audiobookListenNow, .series, .audiobookLibrary, .search]
            case .podcasts:
                return [.podcastListenNow, .latest, .podcastLibrary, .search]
        }
    }
}
