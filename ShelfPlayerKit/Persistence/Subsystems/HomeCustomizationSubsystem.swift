//
//  HomeCustomizationSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 19.04.26.
//

import Combine
import Foundation
import SwiftData
import OSLog

typealias PersistedHomeCustomization = ShelfPlayerSchema.PersistedHomeCustomization

extension PersistenceManager {
    @ModelActor
    public final actor HomeCustomizationSubsystem: Sendable {
        public final class EventSource: @unchecked Sendable {
            public let invalidateSections = PassthroughSubject<HomeScope, Never>()

            init() {}
        }

        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "HomeCustomizationSubsystem")
        public nonisolated let events = EventSource()
    }
}

public extension PersistenceManager.HomeCustomizationSubsystem {
    // MARK: - Available kinds

    /// Every kind that can appear in a start page for the given library type.
    /// Server-row kinds are reported using the canonical row ids the server
    /// sends; the UI renders whatever rows the server has actually returned.
    ///
    /// Only kinds that can actually surface content for the given library type
    /// are returned. Podcast-only kinds (next-up podcasts, downloaded episodes)
    /// are omitted from audiobook libraries; audiobook-only kinds (bookmarks,
    /// downloaded audiobooks, series rows, discover, newest-authors) are
    /// omitted from podcast libraries. The Listen Now rows are excluded too —
    /// in a single-library scope they would just duplicate the server-driven
    /// `continue-listening` row.
    nonisolated func availableKinds(for libraryType: LibraryMediaType) -> [HomeSectionKind] {
        switch libraryType {
        case .audiobooks:
            // ABS `/personalized` returns continue-listening, continue-series,
            // recent-series, recently-added, discover, listen-again, and
            // newest-authors for book libraries. continue-reading / read-again
            // are ebook-only and ShelfPlayer is audio-only, so they're omitted.
            [
                .upNext,
                .serverRow(id: "continue-listening"),
                .serverRow(id: "continue-series"),
                .serverRow(id: "recent-series"),
                .serverRow(id: "recently-added"),
                .serverRow(id: "listen-again"),
                .serverRow(id: "discover"),
                .serverRow(id: "newest-authors"),
                .downloadedAudiobooks,
                .bookmarks,
            ]
        case .podcasts:
            // ABS `/personalized` only returns continue-listening,
            // newest-episodes, recently-added, and listen-again for podcast
            // libraries — `discover` / `newest-authors` / series rows are
            // book-only.
            [
                .upNext,
                .nextUpPodcasts,
                .serverRow(id: "continue-listening"),
                .serverRow(id: "newest-episodes"),
                .serverRow(id: "recently-added"),
                .serverRow(id: "listen-again"),
                .downloadedEpisodes,
            ]
        }
    }

    // MARK: - Defaults

    /// Default section list used when a scope has no saved customization.
    /// `continue-listening` is always first — it surfaces in-progress items,
    /// which is the most common reason to open the app.
    nonisolated func defaultSections(for libraryType: LibraryMediaType) -> [HomeSection] {
        switch libraryType {
        case .audiobooks:
            [
                .init(kind: .serverRow(id: "continue-listening")),
                .init(kind: .upNext),
                .init(kind: .serverRow(id: "continue-series")),
                .init(kind: .serverRow(id: "recent-series")),
                .init(kind: .serverRow(id: "recently-added")),
                .init(kind: .serverRow(id: "listen-again")),
                .init(kind: .serverRow(id: "discover")),
                .init(kind: .serverRow(id: "newest-authors")),
                .init(kind: .downloadedAudiobooks),
            ]
        case .podcasts:
            [
                .init(kind: .serverRow(id: "continue-listening")),
                .init(kind: .upNext),
                .init(kind: .nextUpPodcasts),
                .init(kind: .serverRow(id: "newest-episodes")),
                .init(kind: .serverRow(id: "recently-added")),
                .init(kind: .serverRow(id: "listen-again")),
                .init(kind: .downloadedEpisodes),
            ]
        }
    }

    /// The multi-library panel starts with a small, obvious set. The user
    /// picks per-section libraries from the editor.
    nonisolated func defaultMultiLibrarySections() -> [HomeSection] {
        [
            .init(kind: .listenNowAudiobooks),
            .init(kind: .listenNowEpisodes),
            .init(kind: .upNext),
        ]
    }

    /// Kinds available in the multi-library panel. Server rows are excluded
    /// because they are per-library; collection/playlist rows are added via
    /// the dedicated picker flow in the editor.
    nonisolated func availableMultiLibraryKinds() -> [HomeSectionKind] {
        [
            .listenNowAudiobooks,
            .listenNowEpisodes,
            .upNext,
            .nextUpPodcasts,
            .downloadedAudiobooks,
            .downloadedEpisodes,
            .bookmarks,
        ]
    }

    // MARK: - Read / write

    func sections(for scope: HomeScope, libraryType: LibraryMediaType?) -> [HomeSection] {
        let scopeKey = scope.key

        let entity: PersistedHomeCustomization?
        do {
            entity = try modelContext.fetch(FetchDescriptor<PersistedHomeCustomization>(predicate: #Predicate { $0.scopeKey == scopeKey })).first
        } catch {
            logger.warning("Failed to fetch home customization for \(scopeKey, privacy: .public); falling back to defaults: \(error, privacy: .public)")
            entity = nil
        }

        if let entity {
            do {
                return try JSONDecoder().decode([HomeSection].self, from: entity.sectionsData)
            } catch {
                logger.warning("Failed to decode home customization for \(scopeKey, privacy: .public); falling back to defaults: \(error, privacy: .public)")
            }
        }

        switch scope {
        case .library:
            return defaultSections(for: libraryType ?? .audiobooks)
        case .multiLibrary:
            return defaultMultiLibrarySections()
        }
    }

    func setSections(_ sections: [HomeSection]?, for scope: HomeScope) async throws {
        let scopeKey = scope.key

        if let sections {
            let data = try JSONEncoder().encode(sections)

            if let existing = try modelContext.fetch(FetchDescriptor<PersistedHomeCustomization>(predicate: #Predicate { $0.scopeKey == scopeKey })).first {
                existing.sectionsData = data
            } else {
                modelContext.insert(PersistedHomeCustomization(scopeKey: scopeKey, sectionsData: data))
            }
        } else {
            try modelContext.delete(model: PersistedHomeCustomization.self, where: #Predicate { $0.scopeKey == scopeKey })
        }

        try modelContext.save()

        let broadcastScope = scope
        await MainActor.run {
            events.invalidateSections.send(broadcastScope)
        }
    }

    func purgeAll() {
        do {
            try modelContext.delete(model: PersistedHomeCustomization.self)
        } catch {
            logger.warning("Failed to delete persisted home customizations: \(error, privacy: .public)")
        }
        do {
            try modelContext.save()
        } catch {
            logger.warning("Failed to save context after purging home customizations: \(error, privacy: .public)")
        }
    }
}
