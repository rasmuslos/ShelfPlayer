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

extension Sidebar {
    struct Selection: Codable, Hashable, Defaults.Serializable {
        let libraryId: String
        let panel: Panel
    }
    
    enum Panel: Codable, Hashable, Defaults.Serializable {
        case audiobookListenNow
        case series
        case authors
        
        case audiobookLibrary
        
        case podcastListenNow
        case podcastLibrary
        case latest
        
        case search
        
        case audiobook(id: String)
        case author(id: String)
        case singleSeries(name: String)
        case podcast(id: String)
        case episode(id: String, podcastId: String)
    }
}

extension Sidebar.Panel {
    var label: LocalizedStringKey? {
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
            default:
                nil
        }
    }
    
    var icon: String? {
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
            default:
                nil
        }
    }
    
    var content: some View {
        Group {
            switch self {
                case .audiobookListenNow:
                    AudiobookListenNowView()
                case .series:
                    AudiobookSeriesView()
                case .authors:
                    AuthorsView()
                case .audiobookLibrary:
                    AudiobookLibraryView()
                    
                case .podcastListenNow:
                    PodcastListenNowView()
                case .latest:
                    PodcastLatestView()
                case .podcastLibrary:
                    PodcastLibraryView()
                    
                case .search:
                    SearchView()
                    
                case .audiobook(let id):
                    AudiobookLoadView(audiobookId: id)
                case .author(let id):
                    AuthorLoadView(authorId: id)
                case .singleSeries(let name):
                    SeriesLoadView(series: .init(id: nil, name: name, sequence: nil))
                case .podcast(let id):
                    PodcastLoadView(podcastId: id)
                case .episode(let id, let podcastId):
                    EpisodeLoadView(id: id, podcastId: podcastId)
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
