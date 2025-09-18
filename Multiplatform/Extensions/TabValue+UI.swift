//
//  TabValue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import SwiftUI
import ShelfPlayback

extension TabValue {
    var label: String {
        switch self {
            case .audiobookHome:
                String(localized: "panel.home")
            case .audiobookSeries:
                String(localized: "panel.series")
            case .audiobookAuthors:
                String(localized: "panel.authors")
            case .audiobookNarrators:
                String(localized: "panel.narrators")
            case .audiobookBookmarks:
                String(localized: "panel.bookmarks")
            case .audiobookCollections:
                String(localized: "panel.collections")
            case .audiobookLibrary:
                String(localized: "panel.library")
                
            case .podcastHome:
                String(localized: "panel.home")
            case .podcastLatest:
                String(localized: "panel.latest")
            case .podcastLibrary:
                String(localized: "panel.library")
                
            case .playlists:
                String(localized: "panel.playlists")
                
            case .search:
                String(localized: "panel.search")
                
            case .custom(let tabValue):
                tabValue.label
        }
    }
    
    var image: String {
        switch self {
            case .audiobookHome:
                "house.fill"
            case .audiobookSeries:
                ItemIdentifier.ItemType.series.icon
            case .audiobookAuthors:
                ItemIdentifier.ItemType.author.icon
            case .audiobookNarrators:
                ItemIdentifier.ItemType.narrator.icon
            case .audiobookCollections:
                ItemIdentifier.ItemType.collection.icon
            case .audiobookBookmarks:
                "bookmark.fill"
            case .audiobookLibrary:
                "books.vertical.fill"
                
            case .podcastHome:
                "house.fill"
            case .podcastLatest:
                "calendar.badge.clock"
            case .podcastLibrary:
                "square.split.2x2.fill"
                
            case .playlists:
                ItemIdentifier.ItemType.playlist.icon
            case .search:
                "magnifyingglass"
                
            case .custom(let tabValue):
                tabValue.image
        }
    }
    
    @ViewBuilder @MainActor
    var content: some View {
        switch self {
            case .audiobookHome:
                AudiobookHomePanel()
            case .audiobookSeries:
                AudiobookSeriesPanel()
            case .audiobookAuthors:
                AudiobookAuthorsPanel()
            case .audiobookNarrators:
                AudiobookNarratorsPanel()
            case .audiobookBookmarks:
                AudiobookBookmarksPanel()
            case .audiobookCollections:
                CollectionsPanel(type: .collection)
            case .podcastLibrary:
                PodcastLibraryPanel()
                
            case .podcastHome:
                PodcastHomePanel()
            case .podcastLatest:
                PodcastLatestPanel()
            case .audiobookLibrary:
                AudiobookLibraryPanel()
                
            case .playlists:
                CollectionsPanel(type: .playlist)
                
            case .search, .custom:
                fatalError("Access to search and custom tabs is not implemented")
        }
    }
}
