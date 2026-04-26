//
//  PodcastHomePanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct PodcastHomePanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var episodeRowsByID = [String: HomeRow<Episode>]()
    @State private var podcastRowsByID = [String: HomeRow<Podcast>]()

    @State private var sections: [HomeSection] = []

    @State private var didFail = false
    @State private var isLoading = false
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
        !episodeRowsByID.isEmpty || !podcastRowsByID.isEmpty
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
                            PodcastHomeSectionRow(
                                section: section,
                                fallbackLibraryID: library?.id,
                                episodeRowsByID: episodeRowsByID,
                                podcastRowsByID: podcastRowsByID
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .largeTitleDisplayMode()
        .hapticFeedback(.error, trigger: didFail)
        .toolbar {
            if horizontalSizeClass == .compact {
                ListenNowSheetToggle.toolbarItem()

                ToolbarItem(placement: .topBarTrailing) {
                    CompactLibraryPicker(customizeHomeLibraryType: .podcasts)
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .task {
            guard !hasContent && sections.isEmpty else { return }
            await reloadSections()
            fetchItems()
        }
        .refreshable {
            await reloadSections()
            fetchItems(bypassCache: true)
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

private extension PodcastHomePanel {
    func reloadSections() async {
        guard let scope else { return }
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: scope, libraryType: .podcasts)
        // No `withAnimation` here — see AudiobookHomePanel for the rationale.
        sections = loaded
    }

    func fetchItems(bypassCache: Bool = false) {
        Task {
            withAnimation {
                didFail = false
                isLoading = true
            }

            await fetchRemoteItems(bypassCache: bypassCache)

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
            await fetchRemoteItems(bypassCache: true)
        }
    }

    func fetchRemoteItems(bypassCache: Bool = false) async {
        guard let library else {
            return
        }

        do {
            let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID, bypassCache: bypassCache)
            let episodes = await HomeRow.prepareForPresentation(home.1, connectionID: library.id.connectionID)

            withAnimation {
                self.episodeRowsByID = Dictionary(uniqueKeysWithValues: episodes.map { ($0.id, $0) })
                self.podcastRowsByID = Dictionary(uniqueKeysWithValues: home.0.map { ($0.id, $0) })
            }
        } catch {
            withAnimation {
                didFail = true
            }
        }
    }
}

// MARK: - Row

private struct PodcastHomeSectionRow: View {
    let section: HomeSection
    let fallbackLibraryID: LibraryIdentifier?
    let episodeRowsByID: [String: HomeRow<Episode>]
    let podcastRowsByID: [String: HomeRow<Podcast>]

    private var resolvedLibraryID: LibraryIdentifier? {
        section.libraryID ?? fallbackLibraryID
    }

    var body: some View {
        switch section.kind {
        case .serverRow(let id):
            if let row = episodeRowsByID[id], !row.entities.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    RowTitle(title: row.localizedLabel)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)

                    if row.id == "continue-listening" {
                        EpisodeFeaturedGrid(episodes: row.entities)
                    } else {
                        EpisodeGrid(episodes: row.entities)
                    }
                }
            } else if let row = podcastRowsByID[id], !row.entities.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    RowTitle(title: row.localizedLabel)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    PodcastHGrid(podcasts: row.entities)
                }
            }
        case .listenNowAudiobooks, .listenNowEpisodes:
            // Listen Now rows are reserved for the multi-library panel; in a
            // single-library scope they just duplicate `continue-listening`.
            EmptyView()
        case .upNext:
            UpNextRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .nextUpPodcasts:
            NextUpPodcastsRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .downloadedAudiobooks:
            // Audiobook-only row; skip on podcast panel.
            EmptyView()
        case .downloadedEpisodes:
            DownloadedEpisodesRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .bookmarks:
            // Audiobook-only row; skip on podcast panel.
            EmptyView()
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
        PodcastHomePanel()
    }
    .previewEnvironment()
}
#endif
