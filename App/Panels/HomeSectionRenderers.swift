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
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
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
        let ids = AppSettings.shared.playbackResumeQueue.filter { id in
            guard let libraryID else { return true }
            return id.libraryID == libraryID.libraryID && id.connectionID == libraryID.connectionID
        }
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
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
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
        let filtered: [Item]
        if let libraryID {
            filtered = items.filter { $0.id.libraryID == libraryID.libraryID && $0.id.connectionID == libraryID.connectionID }
        } else {
            filtered = items
        }

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
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
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

        // Collect (connectionID::groupingID, mostRecentLastUpdate) from progress of episodes.
        var mostRecent: [String: (connectionID: String, groupingID: String, date: Date)] = [:]
        for entity in active {
            if let libraryID, entity.connectionID != libraryID.connectionID { continue }
            guard let groupingID = entity.groupingID else { continue }
            let key = "\(entity.connectionID)::\(groupingID)"
            if let existing = mostRecent[key] {
                if entity.lastUpdate > existing.date {
                    mostRecent[key] = (entity.connectionID, groupingID, entity.lastUpdate)
                }
            } else {
                mostRecent[key] = (entity.connectionID, groupingID, entity.lastUpdate)
            }
        }

        let ordered = mostRecent.values
            .sorted { $0.date > $1.date }
            .prefix(10)

        var next: [Episode] = []
        for entry in ordered {
            guard let podcast = try? await ResolveCache.shared.resolve(primaryID: entry.groupingID, connectionID: entry.connectionID) else { continue }
            if let libraryID, podcast.id.libraryID != libraryID.libraryID { continue }
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
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
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
            if let libraryID, let (itemID, _) = payload, itemID.libraryID != libraryID.libraryID { return }
            Task { await load() }
        }
    }

    private func load() async {
        let books: [Audiobook]?
        if let libraryID {
            books = try? await PersistenceManager.shared.download.audiobooks(in: libraryID.libraryID)
        } else {
            books = try? await PersistenceManager.shared.download.audiobooks()
        }
        guard let books else { return }
        withAnimation { audiobooks = books }
    }
}

struct DownloadedEpisodesRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
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
            if let libraryID, let (itemID, _) = payload, itemID.libraryID != libraryID.libraryID { return }
            Task { await load() }
        }
    }

    private func load() async {
        let eps: [Episode]?
        if let libraryID {
            eps = try? await PersistenceManager.shared.download.episodes(in: libraryID.libraryID)
        } else {
            eps = try? await PersistenceManager.shared.download.episodes()
        }
        guard let eps else { return }
        withAnimation { episodes = eps }
    }
}

// MARK: - Bookmarks

struct BookmarksRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String

    @State private var count: Int = 0

    @ViewBuilder
    private var rowContent: some View {
        HStack {
            Text(count > 0
                 ? "home.section.bookmarks.count \(count)"
                 : "home.section.bookmarks.empty")
                .foregroundStyle(.secondary)
            Spacer()
            if count > 0, libraryID != nil {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
    }

    var body: some View {
        // Always render when configured — an empty-state message is more
        // useful than a vanishing row, and lets the user confirm the section
        // is actually pinned. Podcast-only libraries don't have bookmarks
        // (bookmarks are audiobook-only) so they still hide.
        Group {
            if let libraryID {
                if libraryID.type == .audiobooks {
                    NavigationLink {
                        AudiobookBookmarksPanel()
                            .environment(\.library, Library(id: libraryID.libraryID, connectionID: libraryID.connectionID, name: title, type: libraryID.type, index: 0))
                    } label: {
                        HomeRowContainer(title: title) { rowContent }
                    }
                    .buttonStyle(.plain)
                    .disabled(count == 0)
                } else {
                    EmptyView()
                }
            } else {
                HomeRowContainer(title: title) { rowContent }
            }
        }
        .task(id: libraryID) { await load() }
    }

    private func load() async {
        if let libraryID {
            guard libraryID.type == .audiobooks else { return }
            guard let dict = try? await PersistenceManager.shared.bookmark[libraryID] else { return }
            let total = dict.values.reduce(0, +)
            withAnimation { count = total }
        } else {
            guard let total = try? await PersistenceManager.shared.bookmark.totalCount else { return }
            withAnimation { count = total }
        }
    }
}

// MARK: - Pinned Collection / Playlist

/// Resolves a pinned `ItemCollection` (collection or playlist) and renders its
/// items as a home row. Always renders once configured — empty or unreachable
/// collections fall back to a placeholder container so the user can see the
/// section is actually pinned.
///
/// Important: this view does NOT wrap its content in a `NavigationLink`.
/// `AudiobookRow` already contains its own `NavigationLink` (for the "see all"
/// destination when there are >5 audiobooks), and nesting NavigationLinks
/// triggers a collection-view recursive-layout loop (UICollectionView
/// feedback-loop crash).
struct PinnedCollectionRow: View {
    let itemID: ItemIdentifier
    /// Optional override title. When nil, the collection's own name is used.
    let titleOverride: String?

    @State private var collection: ItemCollection?
    @State private var didFail = false

    private var fallbackTitle: String {
        titleOverride ?? String(localized: itemID.type == .playlist
                                ? "home.section.playlist"
                                : "home.section.collection")
    }

    var body: some View {
        Group {
            if let collection {
                let displayTitle = titleOverride ?? collection.name
                if let audiobooks = collection.audiobooks, !audiobooks.isEmpty {
                    AudiobookRow(title: displayTitle, small: false, audiobooks: audiobooks)
                } else if let episodes = collection.episodes, !episodes.isEmpty {
                    HomeRowContainer(title: displayTitle) {
                        EpisodeGrid(episodes: episodes)
                    }
                } else {
                    HomeRowContainer(title: displayTitle) {
                        placeholder(textKey: "home.section.collection.empty")
                    }
                }
            } else if didFail {
                HomeRowContainer(title: fallbackTitle) {
                    placeholder(textKey: "home.section.collection.unavailable")
                }
            } else {
                // Brief pre-resolve window — keep quiet to avoid a flash.
                EmptyView()
            }
        }
        .task(id: itemID) { await load() }
        .onReceive(CollectionEventSource.shared.changed) { _ in
            Task { await load() }
        }
    }

    @ViewBuilder
    private func placeholder(textKey: LocalizedStringKey) -> some View {
        HStack {
            Text(textKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func load() async {
        do {
            let resolved = try await ResolveCache.shared.resolve(itemID) as? ItemCollection
            withAnimation {
                collection = resolved
                didFail = resolved == nil
            }
        } catch {
            withAnimation { didFail = true }
        }
    }
}
