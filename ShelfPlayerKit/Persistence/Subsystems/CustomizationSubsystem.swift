//
//  CustomizationSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 17.09.25.
//

import Combine
import Foundation
import SwiftData
import OSLog

typealias PersistedTabCustomization = ShelfPlayerSchema.PersistedTabCustomization

extension PersistenceManager {
    @ModelActor
    public final actor CustomizationSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "CustomizationSubsystem")
    }
}

extension PersistenceManager.CustomizationSubsystem {
    nonisolated func defaultTabs(for library: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
        switch library.type {
        case .audiobooks:
            switch scope {
            case .tabBar:
                [
                    .audiobookHome(library),
                    .audiobookSeries(library),
                    .audiobookAuthors(library),
                    .audiobookLibrary(library),
                ]
            case .library:
                [
                    .audiobookNarrators(library),
                    .audiobookBookmarks(library),
                    .audiobookGenres(library),
                    .audiobookTags(library),
                    .playlists(library),
                    .audiobookCollections(library),
                    .downloaded(library),
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
                    .downloaded(library),
                ]
            }
        }
    }
}

public extension PersistenceManager.CustomizationSubsystem {
    nonisolated func availableTabs(for library: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
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
                    .audiobookGenres(library),
                    .audiobookTags(library),
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
                    .audiobookGenres(library),
                    .audiobookTags(library),
                    .playlists(library),
                    .downloaded(library),
                    .audiobookLibrary(library),
                ]

            case .library:
                [
                    .audiobookSeries(library),
                    .audiobookAuthors(library),
                    .audiobookNarrators(library),
                    .audiobookBookmarks(library),
                    .audiobookCollections(library),
                    .audiobookGenres(library),
                    .audiobookTags(library),
                    .playlists(library),
                    .downloaded(library),
                ]
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

    func configuredTabs(for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
        let compositeKey = "\(libraryID.id)::\(scope.rawValue)"

        let entity: PersistedTabCustomization?
        do {
            entity = try modelContext.fetch(FetchDescriptor<PersistedTabCustomization>(predicate: #Predicate { $0.compositeKey == compositeKey })).first
        } catch {
            logger.warning("Failed to fetch tab customization for \(compositeKey, privacy: .public); falling back to defaults: \(error, privacy: .public)")
            return defaultTabs(for: libraryID, scope: scope)
        }

        guard let entity else {
            return defaultTabs(for: libraryID, scope: scope)
        }

        do {
            return try JSONDecoder().decode([TabValue].self, from: entity.tabsData)
        } catch {
            logger.warning("Failed to decode tab customization for \(compositeKey, privacy: .public); falling back to defaults: \(error, privacy: .public)")
            return defaultTabs(for: libraryID, scope: scope)
        }
    }
    func setConfiguredTabs(_ tabs: [TabValue]?, for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) async throws {
        let compositeKey = "\(libraryID.id)::\(scope.rawValue)"

        if let tabs {
            let data = try JSONEncoder().encode(tabs)

            if let existing = try modelContext.fetch(FetchDescriptor<PersistedTabCustomization>(predicate: #Predicate { $0.compositeKey == compositeKey })).first {
                existing.tabsData = data
            } else {
                modelContext.insert(PersistedTabCustomization(libraryID: libraryID.id, scope: scope.rawValue, tabsData: data))
            }
        } else {
            try modelContext.delete(model: PersistedTabCustomization.self, where: #Predicate { $0.compositeKey == compositeKey })
        }

        try modelContext.save()

        await MainActor.run {
            TabEventSource.shared.invalidateTabs.send()
        }
    }

    func purgeAll() {
        do {
            try modelContext.delete(model: PersistedTabCustomization.self)
        } catch {
            logger.warning("Failed to delete persisted tab customizations: \(error, privacy: .public)")
        }
        do {
            try modelContext.save()
        } catch {
            logger.warning("Failed to save context after purging tab customizations: \(error, privacy: .public)")
        }
    }

    enum TabValueCustomizationScope: String, Identifiable, Sendable {
        case tabBar
        case sidebar

        case library

        public var id: String {
            rawValue
        }

        public static func available(for libraryType: LibraryMediaType) -> [Self] {
            [.tabBar, .library]
        }
    }
}
