//
//  AudiobookHomePanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookHomePanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library

    @State private var audiobookRowsByID = [String: HomeRow<Audiobook>]()
    @State private var authorRowsByID = [String: HomeRow<Person>]()
    @State private var seriesRowsByID = [String: HomeRow<Series>]()

    @State private var sections: [HomeSection] = []

    @State private var didFail = false
    @State private var isLoading = false
    @State private var notifyError = false
    /// Debounce handle for progress-driven refetches. New progress events
    /// cancel the prior pending fetch so a burst of updates collapses to a
    /// single network round-trip.
    @State private var pendingProgressRefresh: Task<Void, Never>?

    private var scope: HomeScope? {
        if let library { return .library(library.id) }
        return nil
    }

    private var visibleSections: [HomeSection] {
        sections.filter { !$0.isHidden }
    }

    private var hasContent: Bool {
        !audiobookRowsByID.isEmpty || !authorRowsByID.isEmpty || !seriesRowsByID.isEmpty
    }

    var body: some View {
        Group {
            if !hasContent && visibleSections.allSatisfy({ $0.kind.isClientDerived == false }) {
                if didFail {
                    ErrorView()
                } else if isLoading {
                    LoadingView()
                } else {
                    EmptyCollectionView()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(visibleSections) { section in
                            AudiobookHomeSectionRow(
                                section: section,
                                fallbackLibraryID: library?.id,
                                audiobookRowsByID: audiobookRowsByID,
                                authorRowsByID: authorRowsByID,
                                seriesRowsByID: seriesRowsByID
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .hapticFeedback(.error, trigger: notifyError)
        .toolbar {
            if horizontalSizeClass == .compact {
                ListenNowSheetToggle.toolbarItem()

                ToolbarItem(placement: .topBarTrailing) {
                    CompactLibraryPicker(customizeHomeLibraryType: .audiobooks)
                }
            }
        }
        .task {
            guard !hasContent && sections.isEmpty else { return }
            await reloadSections()
            fetchItems()
        }
        .refreshable {
            await reloadSections()
            fetchItems(refresh: true)
            ListenedTodayTracker.shared.refresh()
        }
        .onReceive(PlaybackLifecycleEventSource.shared.finalizeReporting) { _ in
            fetchItems()
        }
        .onReceive(PersistenceManager.shared.progress.events.entityUpdated) { _ in
            scheduleProgressRefresh()
        }
        .onReceive(PersistenceManager.shared.progress.events.invalidateEntities) { _ in
            scheduleProgressRefresh()
        }
        .onReceive(PersistenceManager.shared.homeCustomization.events.invalidateSections) { changed in
            if changed == scope {
                Task { await reloadSections() }
            }
        }
        .onDisappear {
            pendingProgressRefresh?.cancel()
            pendingProgressRefresh = nil
        }
    }
}

private extension AudiobookHomePanel {
    func reloadSections() async {
        guard let scope else { return }
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: scope, libraryType: .audiobooks)
        // No `withAnimation` here — animating a section-array change while a
        // sheet transition or GeometryReader remeasure is in flight pushes
        // UICollectionView into a feedback loop.
        sections = loaded
    }

    func fetchItems(refresh: Bool = false) {
        Task {
            withAnimation {
                isLoading = true
                didFail = false
            }

            await fetchRemoteItems(refresh: refresh, bypassCache: refresh)

            withAnimation {
                isLoading = false
            }
        }
    }

    /// Coalesce bursts of progress updates (e.g. mid-playback ticks or a batch
    /// websocket sync) into a single refetch. Refresh after `entityUpdated`
    /// also bypasses the API client cache so freshly-marked-complete items
    /// don't keep reappearing in continue-listening for up to 12 s.
    func scheduleProgressRefresh() {
        pendingProgressRefresh?.cancel()
        pendingProgressRefresh = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await fetchRemoteItems(refresh: false, bypassCache: true)
        }
    }

    func fetchRemoteItems(refresh: Bool, bypassCache: Bool = false) async {
        guard let library else {
            return
        }

        let discoverRow = refresh ? nil : audiobookRowsByID["discover"]

        do {
            let home: ([HomeRow<Audiobook>], [HomeRow<Person>], [HomeRow<Series>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID, bypassCache: bypassCache)
            let audiobooks = await HomeRow.prepareForPresentation(home.0, connectionID: library.id.connectionID).map {
                if $0.id == "discover", let discoverRow {
                    discoverRow
                } else {
                    $0
                }
            }

            withAnimation {
                authorRowsByID = Dictionary(uniqueKeysWithValues: home.1.map { ($0.id, $0) })
                audiobookRowsByID = Dictionary(uniqueKeysWithValues: audiobooks.map { ($0.id, $0) })
                seriesRowsByID = Dictionary(uniqueKeysWithValues: home.2.map { ($0.id, $0) })
            }
        } catch {
            withAnimation {
                didFail = true
                notifyError.toggle()
            }
        }
    }
}

// MARK: - Row

private struct AudiobookHomeSectionRow: View {
    let section: HomeSection
    let fallbackLibraryID: LibraryIdentifier?
    let audiobookRowsByID: [String: HomeRow<Audiobook>]
    let authorRowsByID: [String: HomeRow<Person>]
    let seriesRowsByID: [String: HomeRow<Series>]

    private var resolvedLibraryID: LibraryIdentifier? {
        section.libraryID ?? fallbackLibraryID
    }

    var body: some View {
        switch section.kind {
        case .serverRow(let id):
            if let row = authorRowsByID[id], !row.entities.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    RowTitle(title: row.localizedLabel)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    PersonGrid(people: row.entities)
                }
            } else if let row = seriesRowsByID[id], !row.entities.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    RowTitle(title: row.localizedLabel)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    SeriesHGrid(series: row.entities)
                }
            } else if let row = audiobookRowsByID[id], !row.entities.isEmpty {
                AudiobookRow(title: row.localizedLabel, small: false, audiobooks: row.entities)
            }
        case .listenNowAudiobooks, .listenNowEpisodes:
            // Listen Now rows are reserved for the multi-library panel; in a
            // single-library scope they just duplicate `continue-listening`.
            EmptyView()
        case .upNext:
            UpNextRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .nextUpPodcasts:
            // Podcast-only row; skip on audiobook panel.
            EmptyView()
        case .downloadedAudiobooks:
            DownloadedAudiobooksRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .downloadedEpisodes:
            // Podcast-only row; skip on audiobook panel.
            EmptyView()
        case .bookmarks:
            BookmarksRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .collection(let itemID), .playlist(let itemID):
            if ItemIdentifier.isValid(itemID) {
                PinnedCollectionRow(itemID: ItemIdentifier(string: itemID), titleOverride: nil)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookHomePanel()
    }
    .previewEnvironment()
}
#endif
