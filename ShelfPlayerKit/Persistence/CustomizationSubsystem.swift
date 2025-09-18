//
//  CustomizationSubsystem.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import Foundation
import OSLog

extension PersistenceManager {
    public final class CustomizationSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "CustomizationSubsystem")
    }
}

public extension PersistenceManager.CustomizationSubsystem {
//    static func options(for library: Library) -> [TabValue] {
//        switch library.type {
//            case .audiobooks:
//                [
//                    .audiobookHome(library),
//                    .audiobookSeries(library),
//                    /*
//                    .audiobookAuthors(library),
//                    .audiobookNarrators(library),
//                    .audiobookBookmarks(library),
//                    .audiobookCollections(library),
//                    .playlists(library),
//                     */
//                    .audiobookLibrary(library),
//                ]
//            case .podcasts:
//                [
//                    .podcastHome(library),
//                    .podcastLatest(library),
//                    .playlists(library),
//                    .podcastLibrary(library),
//                ]
//        }
//    }
    
    func availableTabs(for library: Library) -> [TabValue] {
        switch library.type {
            case .audiobooks:
                [
                    .audiobookHome(library),
                    .audiobookSeries(library),
                     .audiobookAuthors(library),
                     .audiobookNarrators(library),
                     .audiobookBookmarks(library),
                     .audiobookCollections(library),
                     .playlists(library),
                    .audiobookLibrary(library),
                ]
            case .podcasts:
                [
                    .podcastHome(library),
                    .podcastLatest(library),
                    .playlists(library),
                    .podcastLibrary(library),
                ]
        }
    }
    func configuredTabs(for library: Library, scope: TabValueCustomizationScope) -> [TabValue] {
        defaultTabs(for: library, scope: scope)
    }
    
    enum TabValueCustomizationScope: String {
        case tabBar
        case library
        
        public static func available(for libraryType: Library.MediaType) -> [Self] {
            switch libraryType {
                case .audiobooks:
                    [.tabBar, .library]
                case .podcasts:
                    [.tabBar]
            }
        }
    }
}

private extension PersistenceManager.CustomizationSubsystem {
    func defaultTabs(for library: Library, scope: TabValueCustomizationScope) -> [TabValue] {
        switch library.type {
            case .audiobooks:
                [
                    .audiobookHome(library),
                    .audiobookLibrary(library),
                ]
            case .podcasts:
                [
                    .podcastHome(library),
                    .podcastLatest(library),
                    .playlists(library),
                    .podcastLibrary(library),
                ]
        }
    }
}
