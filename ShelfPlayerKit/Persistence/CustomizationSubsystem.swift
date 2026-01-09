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

extension PersistenceManager.CustomizationSubsystem {
    func defaultTabs(for library: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
        switch library.type {
            case .audiobooks:
                switch scope {
                    case .tabBar:
                        [
                            .audiobookHome(library),
                            .audiobookLibrary(library),
                        ]
                    case .library:
                        [
                            .audiobookSeries(library),
                            .audiobookAuthors(library),
                            .audiobookNarrators(library),
                            .audiobookBookmarks(library),
                            .audiobookCollections(library),
                            .playlists(library),
                        ]
                    case .sidebar:
                        availableTabs(for: library, scope: scope)
                }
            case .podcasts:
                switch scope {
                    case .tabBar, .sidebar:
                        [
                            .podcastHome(library),
                            .podcastLatest(library),
                            .podcastLibrary(library),
                        ]
                    case .library:
                        [
                            .podcastLatest(library),
                            .playlists(library),
                        ]
                }
        }
    }
}

public extension PersistenceManager.CustomizationSubsystem {
    func availableTabs(for library: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
        switch library.type {
            case .audiobooks:
                switch scope {
                    case .tabBar:
                        [
                            .audiobookHome(library),
                            .audiobookSeries(library),
                            .audiobookAuthors(library),
                            .audiobookNarrators(library),
                            .audiobookBookmarks(library),
                            .audiobookCollections(library),
                            .playlists(library),
                            .downloaded(library),
                            .audiobookLibrary(library),
                        ]
                        
                    case .sidebar:
                        [
                            .audiobookHome(library),
                            .audiobookSeries(library),
                            .audiobookAuthors(library),
                            .audiobookNarrators(library),
                            .audiobookBookmarks(library),
                            .audiobookCollections(library),
                            .playlists(library),
                            .downloaded(library),
                            .audiobookLibrary(library),
                        ]
                        
                    case .library:
                        defaultTabs(for: library, scope: .library)
                }
            case .podcasts:
                switch scope {
                    case .tabBar, .sidebar:
                        [
                            .podcastHome(library),
                            .podcastLatest(library),
                            .playlists(library),
                            .downloaded(library),
                            .podcastLibrary(library),
                        ]
                    case .library:
                        [
                            .podcastLatest(library),
                            .playlists(library),
                            .downloaded(library),
                        ]
                }
        }
    }
    
    func configuredTabs(for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) async -> [TabValue] {
        await PersistenceManager.shared.keyValue[.storedTabIDs(for: libraryID, scope: scope)] ?? defaultTabs(for: libraryID, scope: scope)
    }
    func setConfiguredTabs(_ tabs: [TabValue]?, for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) async throws {
        try await PersistenceManager.shared.keyValue.set(.storedTabIDs(for: libraryID, scope: scope), tabs)
        await RFNotification[.invalidateTabs].send()
    }
    
    enum TabValueCustomizationScope: String, Identifiable, Sendable {
        case tabBar
        case sidebar
        
        case library
        
        public var id: String {
            rawValue
        }
        
        public static func available(for libraryType: LibraryMediaType) -> [Self] {
            switch libraryType {
                case .audiobooks:
                    [.tabBar, .library]
                case .podcasts:
                    [.tabBar]
            }
        }
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func storedTabIDs(for libraryID: LibraryIdentifier, scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope) -> Key<[TabValue]> {
        Key(identifier: "storedTabIDs_\(libraryID)_\(scope)", cluster: "storedTabIDs", isCachePurgeable: false)
    }
}
