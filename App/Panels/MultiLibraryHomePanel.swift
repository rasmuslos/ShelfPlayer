//
//  MultiLibraryHomePanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.26.
//

import SwiftUI
import ShelfPlayback

struct MultiLibraryHomePanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var sections: [HomeSection] = []
    @State private var isLoadingSections = true

    private var visibleSections: [HomeSection] {
        sections.filter { !$0.isHidden }
    }

    var body: some View {
        Group {
            if isLoadingSections {
                LoadingView()
            } else if visibleSections.isEmpty {
                // Only-explicit empty state: the user has actively removed
                // every section from their multi-library home customization.
                // We deliberately don't aggregate "every row reports empty"
                // here — listen-now / progress can transiently return [] for
                // legitimate reasons (offline mode, mid-sync, slow resolver),
                // and surfacing "Nothing to show yet" in those cases is
                // misleading.
                emptyState
            } else {
                ScrollView {
                    // VStack (eager) instead of LazyVStack: when a row's
                    // initial body is `EmptyView()` (the brief moment between
                    // mount and the first .task completion populating
                    // `hasLoaded`), LazyVStack can fail to realize the row at
                    // all — its .task never fires, hasLoaded stays false, and
                    // the row stays invisible permanently. Eager mount avoids
                    // that. With at most a dozen sections the perf cost is
                    // negligible; each row's actual content is itself lazy
                    // (its own ScrollView / task).
                    VStack(spacing: 16) {
                        ForEach(visibleSections) { section in
                            MultiLibraryHomeSectionRow(section: section)
                        }
                    }
                }
            }
        }
        .navigationTitle("panel.multiLibrary")
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .toolbar {
            if horizontalSizeClass == .compact {
                ListenNowSheetToggle.toolbarItem()

                ToolbarItem(placement: .topBarTrailing) {
                    CompactLibraryPicker(customizeLibrary: true, isMultiLibraryScope: true)
                }
            }
        }
        .task {
            // Reload unconditionally on every appear. The `invalidateSections`
            // event on the customization subsystem is the primary refresh
            // path, but losing one of those — e.g. if the panel was
            // re-created while the customization sheet was up — used to leave
            // the panel showing stale (or worse, empty) section state.
            await reloadSections()
        }
        .refreshable {
            await reloadSections()
            ListenedTodayTracker.shared.refresh()
        }
        .onReceive(PersistenceManager.shared.homeCustomization.events.invalidateSections) { changed in
            if changed == .multiLibrary {
                Task { await reloadSections() }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        UnavailableWrapper {
            ContentUnavailableView(
                "home.multiLibrary.empty",
                systemImage: "rectangle.3.group",
                description: Text("home.multiLibrary.empty.description")
            )
        }
    }
}

private extension MultiLibraryHomePanel {
    func reloadSections() async {
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: .multiLibrary, libraryType: nil)
        sections = loaded
        isLoadingSections = false
    }
}

// MARK: - Row

private struct MultiLibraryHomeSectionRow: View {
    let section: HomeSection

    var body: some View {
        switch section.kind {
        case .serverRow:
            // Server rows are per-library and not offered in this panel.
            EmptyView()
        case .listenNowAudiobooks:
            ListenNowAudiobooksRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle, showEmptyPlaceholder: true)
        case .listenNowEpisodes:
            ListenNowEpisodesRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle, showEmptyPlaceholder: true)
        case .upNext:
            UpNextRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle, showEmptyPlaceholder: true)
        case .nextUpPodcasts:
            if section.libraryID == nil || section.libraryID?.type == .podcasts {
                NextUpPodcastsRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle, showEmptyPlaceholder: true)
            }
        case .downloadedAudiobooks:
            if section.libraryID == nil || section.libraryID?.type == .audiobooks {
                DownloadedAudiobooksRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
            }
        case .downloadedEpisodes:
            if section.libraryID == nil || section.libraryID?.type == .podcasts {
                DownloadedEpisodesRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
            }
        case .bookmarks:
            if section.libraryID == nil || section.libraryID?.type == .audiobooks {
                BookmarksRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
            }
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
        MultiLibraryHomePanel()
    }
    .previewEnvironment()
}
#endif
