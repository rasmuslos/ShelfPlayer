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
    @State private var isLoading = true

    private var visibleSections: [HomeSection] {
        sections.filter { !$0.isHidden }
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if visibleSections.isEmpty {
                EmptyCollectionView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
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
            guard sections.isEmpty else { return }
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
}

private extension MultiLibraryHomePanel {
    func reloadSections() async {
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: .multiLibrary, libraryType: nil)
        sections = loaded
        isLoading = false
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
        case .listenNow:
            ListenNowRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
        case .upNext:
            UpNextRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
        case .nextUpPodcasts:
            if section.libraryID == nil || section.libraryID?.type == .podcasts {
                NextUpPodcastsRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
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
            BookmarksRow(libraryID: section.libraryID, title: section.kind.defaultLocalizedTitle)
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
