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
        public final class EventSource: @unchecked Sendable {
            public let invalidateTabs = PassthroughSubject<Void, Never>()

            init() {}
        }

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "CustomizationSubsystem")
        public nonisolated let events = EventSource()
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
                    .audiobookCollections(library),
                    .audiobookLibrary(library),
                ]
            case .library:
                [
                    .audiobookAuthors(library),
                    .audiobookNarrators(library),
                    .audiobookBookmarks(library),
                    .audiobookGenres(library),
                    .audiobookTags(library),
                    .playlists(library),
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

    func configuredTabs(for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) -> [TabValue] {
        let compositeKey = "\(libraryID)::\(scope.rawValue)"

        guard let entity = try? modelContext.fetch(FetchDescriptor<PersistedTabCustomization>(predicate: #Predicate { $0.compositeKey == compositeKey })).first,
              let tabs = try? JSONDecoder().decode([TabValue].self, from: entity.tabsData) else {
            return defaultTabs(for: libraryID, scope: scope)
        }

        return tabs
    }
    func setConfiguredTabs(_ tabs: [TabValue]?, for libraryID: LibraryIdentifier, scope: TabValueCustomizationScope) async throws {
        let compositeKey = "\(libraryID)::\(scope.rawValue)"

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
            events.invalidateTabs.send()
        }
    }

    func purgeAll() {
        try? modelContext.delete(model: PersistedTabCustomization.self)
        try? modelContext.save()
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
