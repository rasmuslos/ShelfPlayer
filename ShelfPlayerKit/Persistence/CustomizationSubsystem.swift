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
    func availableTabs(for library: Library, scope: TabValueCustomizationScope) -> [TabValue] {
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
                            .audiobookLibrary(library),
                        ]
                        
                    case .library:
                        defaultTabs(for: library, scope: .library)
                }
            case .podcasts:
                [
                    .podcastHome(library),
                    .podcastLatest(library),
                    .playlists(library),
                    .podcastLibrary(library),
                ]
        }
    }
    
    func defaultTabs(for library: Library, scope: TabValueCustomizationScope) -> [TabValue] {
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
                        fatalError()
                }
            case .podcasts:
                [
                    .podcastHome(library),
                    .podcastLatest(library),
                    .playlists(library),
                    .podcastLibrary(library),
                ]
        }
    }
    
    func configuredTabs(for library: Library, scope: TabValueCustomizationScope) async -> [TabValue] {
        await PersistenceManager.shared.keyValue[.storedTabValues(for: library, scope: scope)] ?? defaultTabs(for: library, scope: scope)
    }
    func setConfiguredTabs(_ tabs: [TabValue]?, for library: Library, scope: TabValueCustomizationScope) async throws {
        try await PersistenceManager.shared.keyValue.set(.storedTabValues(for: library, scope: scope), tabs)
        await RFNotification[.invalidateTabs].send()
    }
    
    enum TabValueCustomizationScope: String, Identifiable, Sendable {
        case tabBar
        case sidebar
        
        case library
        
        public var id: String {
            rawValue
        }
        
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

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func storedTabValues(for library: Library, scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope) -> Key<[TabValue]> {
        Key(identifier: "storedTabValues_\(library.connectionID)_\(library.id)_\(scope.id)", cluster: "storedTabValues", isCachePurgeable: false)
    }
}
