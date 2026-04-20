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
    nonisolated func availableKinds(for libraryType: LibraryMediaType) -> [HomeSectionKind] {
        switch libraryType {
        case .audiobooks:
            [
                .listenNow,
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
            [
                .listenNow,
                .upNext,
                .nextUpPodcasts,
                .serverRow(id: "continue-listening"),
                .serverRow(id: "newest-episodes"),
                .serverRow(id: "recently-added"),
                .serverRow(id: "listen-again"),
                .serverRow(id: "discover"),
                .downloadedEpisodes,
                .bookmarks,
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
                .init(kind: .serverRow(id: "discover")),
                .init(kind: .downloadedEpisodes),
            ]
        }
    }

    /// Pinned-tab start pages start with a small, obvious set. The user picks
    /// per-section libraries from the editor.
    nonisolated func defaultPinnedSections() -> [HomeSection] {
        [
            .init(kind: .listenNow),
            .init(kind: .upNext),
        ]
    }

    // MARK: - Read / write

    func sections(for scope: HomeScope, libraryType: LibraryMediaType?) -> [HomeSection] {
        let scopeKey = scope.key

        let loaded: [HomeSection]
        if let entity = try? modelContext.fetch(FetchDescriptor<PersistedHomeCustomization>(predicate: #Predicate { $0.scopeKey == scopeKey })).first,
           let decoded = try? JSONDecoder().decode([HomeSection].self, from: entity.sectionsData) {
            loaded = decoded
        } else {
            switch scope {
            case .library:
                loaded = defaultSections(for: libraryType ?? .audiobooks)
            case .pinned:
                loaded = defaultPinnedSections()
            }
        }

        return loaded
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
        try? modelContext.delete(model: PersistedHomeCustomization.self)
        try? modelContext.save()
    }
}
