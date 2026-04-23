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
            fetchItems()
            ListenedTodayTracker.shared.refresh()
        }
        .onReceive(PlaybackLifecycleEventSource.shared.finalizeReporting) { _ in
            fetchItems()
        }
        .onReceive(PersistenceManager.shared.homeCustomization.events.invalidateSections) { changed in
            if changed == scope {
                Task { await reloadSections() }
            }
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

    func fetchItems() {
        Task {
            withAnimation {
                didFail = false
                isLoading = true
            }

            await fetchRemoteItems()

            withAnimation {
                isLoading = false
            }
        }
    }

    func fetchRemoteItems() async {
        guard let library else {
            return
        }

        do {
            let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID)
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
        case .listenNow:
            ListenNowRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .upNext:
            UpNextRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
        case .nextUpPodcasts:
            if resolvedLibraryID == nil || resolvedLibraryID?.type == .podcasts {
                NextUpPodcastsRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
            }
        case .downloadedAudiobooks:
            if resolvedLibraryID == nil || resolvedLibraryID?.type == .audiobooks {
                DownloadedAudiobooksRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
            }
        case .downloadedEpisodes:
            if resolvedLibraryID == nil || resolvedLibraryID?.type == .podcasts {
                DownloadedEpisodesRow(libraryID: resolvedLibraryID, title: section.kind.defaultLocalizedTitle)
            }
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
        PodcastHomePanel()
    }
    .previewEnvironment()
}
#endif
