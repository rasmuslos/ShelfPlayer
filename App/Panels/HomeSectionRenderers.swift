//
//  HomeSectionRenderers.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//
//  Shared row views that render the client-derived home sections (listen now,
//  up next, downloads, bookmarks). Server rows are rendered directly by
//  `AudiobookHomePanel` / `PodcastHomePanel` because they already hold the
//  fetched `HomeRow<Audiobook>` / `HomeRow<Episode>` data.

import SwiftUI
import ShelfPlayback

// MARK: - Wrapper

/// A client-derived home row with a leading title + trailing content.
struct HomeRowContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowTitle(title: title)
                .padding(.bottom, 12)
                .padding(.horizontal, 20)

            content()
        }
    }
}

// MARK: - Up Next

struct UpNextRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var audiobooks: [Audiobook] = []
    @State private var episodes: [Episode] = []

    var body: some View {
        Group {
            if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            } else if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeFeaturedGrid(episodes: episodes)
                }
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.progress.events.entityUpdated) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        let ids = AppSettings.shared.playbackResumeQueue.filter { $0.libraryID == libraryID.libraryID && $0.connectionID == libraryID.connectionID }
        var resolvedBooks: [Audiobook] = []
        var resolvedEpisodes: [Episode] = []

        for id in ids {
            guard let item = try? await ResolveCache.shared.resolve(primaryID: id.primaryID, groupingID: id.groupingID, connectionID: id.connectionID) else { continue }
            if let book = item as? Audiobook { resolvedBooks.append(book) }
            else if let episode = item as? Episode { resolvedEpisodes.append(episode) }
        }

        withAnimation {
            audiobooks = resolvedBooks
            episodes = resolvedEpisodes
        }
    }
}

// MARK: - Listen Now

struct ListenNowRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var audiobooks: [Audiobook] = []
    @State private var episodes: [Episode] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            }
            if !episodes.isEmpty {
                HomeRowContainer(title: audiobooks.isEmpty ? title : "\(title) \u{2022} \(String(localized: "item.episodes"))") {
                    EpisodeFeaturedGrid(episodes: episodes)
                }
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.listenNow.events.itemsChanged) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        guard let items = try? await PersistenceManager.shared.listenNow.current else { return }
        let filtered = items.filter { $0.id.libraryID == libraryID.libraryID && $0.id.connectionID == libraryID.connectionID }

        withAnimation {
            audiobooks = filtered.compactMap { $0 as? Audiobook }
            episodes = filtered.compactMap { $0 as? Episode }
        }
    }
}

// MARK: - Next Up Podcasts

/// For each recently-played podcast in this library, shows the next unplayed
/// episode. Podcasts are ordered by most recent progress update.
struct NextUpPodcastsRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var episodes: [Episode] = []

    var body: some View {
        Group {
            if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeGrid(episodes: episodes)
                }
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.progress.events.entityUpdated) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        guard let active = try? await PersistenceManager.shared.progress.activeProgressEntities else { return }

        // Collect (podcastID, mostRecentLastUpdate) from progress of episodes in this connection.
        var mostRecent: [String: Date] = [:]
        for entity in active {
            guard entity.connectionID == libraryID.connectionID,
                  let groupingID = entity.groupingID else { continue }
            if let existing = mostRecent[groupingID] {
                if entity.lastUpdate > existing { mostRecent[groupingID] = entity.lastUpdate }
            } else {
                mostRecent[groupingID] = entity.lastUpdate
            }
        }

        let orderedPodcastIDs = mostRecent
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map(\.key)

        var next: [Episode] = []
        for podcastID in orderedPodcastIDs {
            guard let podcast = try? await ResolveCache.shared.resolve(primaryID: podcastID, connectionID: libraryID.connectionID) else { continue }
            guard podcast.id.libraryID == libraryID.libraryID else { continue }
            guard let item = try? await ResolveCache.nextGroupingItem(podcast.id), let episode = item as? Episode else { continue }
            next.append(episode)
        }

        withAnimation {
            episodes = next
        }
    }
}

// MARK: - Downloaded

struct DownloadedAudiobooksRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var audiobooks: [Audiobook] = []

    var body: some View {
        Group {
            if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.download.events.statusChanged) { payload in
            if let (itemID, _) = payload, itemID.libraryID != libraryID.libraryID { return }
            Task { await load() }
        }
    }

    private func load() async {
        guard let books = try? await PersistenceManager.shared.download.audiobooks(in: libraryID.libraryID) else { return }
        withAnimation { audiobooks = books }
    }
}

struct DownloadedEpisodesRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var episodes: [Episode] = []

    var body: some View {
        Group {
            if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeGrid(episodes: episodes)
                }
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.download.events.statusChanged) { payload in
            if let (itemID, _) = payload, itemID.libraryID != libraryID.libraryID { return }
            Task { await load() }
        }
    }

    private func load() async {
        guard let eps = try? await PersistenceManager.shared.download.episodes(in: libraryID.libraryID) else { return }
        withAnimation { episodes = eps }
    }
}

// MARK: - Bookmarks

struct BookmarksRow: View {
    let libraryID: LibraryIdentifier
    let title: String

    @State private var count: Int = 0

    var body: some View {
        Group {
            if libraryID.type == .audiobooks, count > 0 {
                NavigationLink {
                    AudiobookBookmarksPanel()
                        .environment(\.library, Library(id: libraryID.libraryID, connectionID: libraryID.connectionID, name: title, type: libraryID.type, index: 0))
                } label: {
                    HomeRowContainer(title: title) {
                        HStack {
                            Text("home.section.bookmarks.count \(count)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .buttonStyle(.plain)
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
    }

    private func load() async {
        guard libraryID.type == .audiobooks else { return }
        guard let dict = try? await PersistenceManager.shared.bookmark[libraryID] else { return }
        let total = dict.values.reduce(0, +)
        withAnimation { count = total }
    }
}
