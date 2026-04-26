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

// MARK: - Content state

/// Reported by client-derived home rows that may render as `EmptyView` when
/// they have nothing to show. The multi-library panel uses these reports to
/// distinguish "still fetching" from "actually empty" so it can keep its
/// loading indicator up until rows have settled, then surface a real empty
/// state instead of a blank scroll view.
enum HomeRowContentState: Equatable, Sendable {
    case loading
    case empty
    case hasContent
}

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

/// Inline placeholder text used by rows that have completed their initial load
/// with no items but need to show *something* (e.g. inside a multi-library
/// panel where collapsing would leave the screen blank).
private struct EmptyRowMessage: View {
    let key: LocalizedStringKey
    init(_ key: LocalizedStringKey) { self.key = key }

    var body: some View {
        HStack {
            Text(key)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Up Next

struct UpNextRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String
    /// When `true` the row renders an empty-state placeholder instead of
    /// `EmptyView` once the load completes empty. The multi-library panel
    /// passes `true` so the user always sees feedback for every pinned row;
    /// single-library panels keep the default to let the row collapse.
    var showEmptyPlaceholder: Bool = false
    /// Optional callback the multi-library panel uses to know when this row
    /// has finished its initial load and whether it ended up with content.
    var onContentChange: ((HomeRowContentState) -> Void)? = nil

    @State private var audiobooks: [Audiobook] = []
    @State private var episodes: [Episode] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            } else if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeFeaturedGrid(episodes: episodes)
                }
            } else if showEmptyPlaceholder && hasLoaded {
                HomeRowContainer(title: title) {
                    EmptyRowMessage("home.section.upNext.empty")
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

        // Resolve each ID in parallel. On a multi-connection setup (or any
        // cache miss) sequential `await` calls would serialize the network
        // round-trips behind each other; the task group fans them out.
        // Indexed results preserve the user-meaningful queue order.
        let resolved: [(Int, Item)] = await withTaskGroup(of: (Int, Item?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask {
                    let item = try? await ResolveCache.shared.resolve(primaryID: id.primaryID, groupingID: id.groupingID, connectionID: id.connectionID)
                    return (index, item)
                }
            }
            var collected: [(Int, Item)] = []
            for await (index, item) in group {
                if let item { collected.append((index, item)) }
            }
            return collected.sorted { $0.0 < $1.0 }
        }

        let resolvedBooks = resolved.compactMap { $0.1 as? Audiobook }
        let resolvedEpisodes = resolved.compactMap { $0.1 as? Episode }

        withAnimation {
            audiobooks = resolvedBooks
            episodes = resolvedEpisodes
            hasLoaded = true
        }
        onContentChange?(resolvedBooks.isEmpty && resolvedEpisodes.isEmpty ? .empty : .hasContent)
    }
}

// MARK: - Listen Now

/// "Listen Now" — audiobooks half. Filters the shared listen-now queue down to
/// audiobooks (optionally restricted to a single library) and renders them as
/// a horizontal AudiobookRow.
struct ListenNowAudiobooksRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String
    var showEmptyPlaceholder: Bool = false
    var onContentChange: ((HomeRowContentState) -> Void)? = nil

    @State private var audiobooks: [Audiobook] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            } else if showEmptyPlaceholder && hasLoaded {
                HomeRowContainer(title: title) {
                    EmptyRowMessage("home.section.listenNow.empty")
                }
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.listenNow.events.itemsChanged) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        let items = (try? await PersistenceManager.shared.listenNow.current) ?? []
        let filtered: [Item]
        if let libraryID {
            filtered = items.filter { $0.id.libraryID == libraryID.libraryID && $0.id.connectionID == libraryID.connectionID }
        } else {
            filtered = items
        }
        let resolved = filtered.compactMap { $0 as? Audiobook }

        withAnimation {
            audiobooks = resolved
            hasLoaded = true
        }
        onContentChange?(resolved.isEmpty ? .empty : .hasContent)
    }
}

/// "Listen Now" — episodes half. Filters the shared listen-now queue down to
/// episodes and renders them in a featured grid.
struct ListenNowEpisodesRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String
    var showEmptyPlaceholder: Bool = false
    var onContentChange: ((HomeRowContentState) -> Void)? = nil

    @State private var episodes: [Episode] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeFeaturedGrid(episodes: episodes)
                }
            } else if showEmptyPlaceholder && hasLoaded {
                HomeRowContainer(title: title) {
                    EmptyRowMessage("home.section.listenNow.empty")
                }
            } else {
                EmptyView()
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.listenNow.events.itemsChanged) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        let items = (try? await PersistenceManager.shared.listenNow.current) ?? []
        let filtered: [Item]
        if let libraryID {
            filtered = items.filter { $0.id.libraryID == libraryID.libraryID && $0.id.connectionID == libraryID.connectionID }
        } else {
            filtered = items
        }
        let resolved = filtered.compactMap { $0 as? Episode }

        withAnimation {
            episodes = resolved
            hasLoaded = true
        }
        onContentChange?(resolved.isEmpty ? .empty : .hasContent)
    }
}

// MARK: - Next Up Podcasts

/// For each recently-played podcast in this library, shows the next unplayed
/// episode. Podcasts are ordered by most recent progress update.
struct NextUpPodcastsRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String
    var showEmptyPlaceholder: Bool = false
    var onContentChange: ((HomeRowContentState) -> Void)? = nil

    @State private var episodes: [Episode] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeGrid(episodes: episodes)
                }
            } else if showEmptyPlaceholder && hasLoaded {
                HomeRowContainer(title: title) {
                    EmptyRowMessage("home.section.nextUpPodcasts.empty")
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
        guard let active = try? await PersistenceManager.shared.progress.activeProgressEntities else {
            withAnimation { hasLoaded = true }
            onContentChange?(.empty)
            return
        }

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

        let ordered = Array(
            mostRecent.values
                .sorted { $0.date > $1.date }
                .prefix(10)
        )

        // Resolve podcast → next-grouping-item in parallel across entries.
        // Each entry crosses up to two API calls on a cache miss; doing them
        // serially blocked all-but-one connection at a time when the user has
        // multiple servers. Indexed results preserve the most-recent order.
        let resolved: [(Int, Episode)] = await withTaskGroup(of: (Int, Episode?).self) { group in
            for (index, entry) in ordered.enumerated() {
                let captureLibraryID = libraryID
                group.addTask {
                    guard let podcast = try? await ResolveCache.shared.resolve(primaryID: entry.groupingID, connectionID: entry.connectionID) else {
                        return (index, nil)
                    }
                    if let captureLibraryID, podcast.id.libraryID != captureLibraryID.libraryID {
                        return (index, nil)
                    }
                    guard let item = try? await ResolveCache.nextGroupingItem(podcast.id),
                          let episode = item as? Episode else {
                        return (index, nil)
                    }
                    return (index, episode)
                }
            }
            var collected: [(Int, Episode)] = []
            for await (index, episode) in group {
                if let episode { collected.append((index, episode)) }
            }
            return collected.sorted { $0.0 < $1.0 }
        }
        let next = resolved.map(\.1)

        withAnimation {
            episodes = next
            hasLoaded = true
        }
        onContentChange?(next.isEmpty ? .empty : .hasContent)
    }
}

// MARK: - Downloaded

struct DownloadedAudiobooksRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String

    @State private var audiobooks: [Audiobook] = []
    @State private var hasLoaded = false

    var body: some View {
        // Always render once configured. Hiding the row when empty made
        // freshly-pinned downloaded rows look broken — users couldn't tell
        // whether the section was disabled, the data hadn't loaded, or they
        // simply had no downloads. Mirrors `BookmarksRow`.
        Group {
            if libraryID?.type == .podcasts {
                EmptyView()
            } else if !audiobooks.isEmpty {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            } else if hasLoaded {
                HomeRowContainer(title: title) {
                    HStack {
                        Text("home.section.downloadedAudiobooks.empty")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
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
        let books: [Audiobook]?
        if let libraryID {
            books = try? await PersistenceManager.shared.download.audiobooks(in: libraryID.libraryID)
        } else {
            books = try? await PersistenceManager.shared.download.audiobooks()
        }
        withAnimation {
            audiobooks = books ?? []
            hasLoaded = true
        }
    }
}

struct DownloadedEpisodesRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String

    @State private var episodes: [Episode] = []
    @State private var hasLoaded = false

    var body: some View {
        // See `DownloadedAudiobooksRow` — always render once configured.
        Group {
            if libraryID?.type == .audiobooks {
                EmptyView()
            } else if !episodes.isEmpty {
                HomeRowContainer(title: title) {
                    EpisodeGrid(episodes: episodes)
                }
            } else if hasLoaded {
                HomeRowContainer(title: title) {
                    HStack {
                        Text("home.section.downloadedEpisodes.empty")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
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
        withAnimation {
            episodes = eps ?? []
            hasLoaded = true
        }
    }
}

// MARK: - Bookmarks

struct BookmarksRow: View {
    /// When nil, aggregates across all libraries (pinned-tab "Any" semantics).
    let libraryID: LibraryIdentifier?
    let title: String

    @State private var audiobooks: [Audiobook] = []

    var body: some View {
        // Podcast-only libraries don't have bookmarks (bookmarks are
        // audiobook-only) so they still hide entirely.
        Group {
            if let libraryID, libraryID.type == .podcasts {
                EmptyView()
            } else if audiobooks.isEmpty {
                HomeRowContainer(title: title) {
                    HStack {
                        Text("home.section.bookmarks.empty")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                AudiobookRow(title: title, small: false, audiobooks: audiobooks)
            }
        }
        .task(id: libraryID) { await load() }
        .onReceive(PersistenceManager.shared.bookmark.events.changed) { _ in
            Task { await load() }
        }
    }

    private func load() async {
        // Collect bookmarked audiobook identifiers (primaryID / connectionID
        // pairs), optionally filtering by the current library.
        var identifiers: [(primaryID: String, connectionID: String)] = []

        if let libraryID {
            guard libraryID.type == .audiobooks else { return }
            guard let dict = try? await PersistenceManager.shared.bookmark[libraryID] else { return }
            // Sort by bookmark count desc so the busiest books lead the row.
            let sorted = dict.sorted { $0.value > $1.value }
            identifiers = sorted.map { ($0.key, libraryID.connectionID) }
        } else {
            guard let all = try? await PersistenceManager.shared.bookmark.all else { return }
            // Unique by (connectionID, primaryID) preserving first-seen order.
            var seen = Set<String>()
            for entry in all {
                let key = "\(entry.connectionID)::\(entry.primaryID)"
                if seen.insert(key).inserted {
                    identifiers.append((entry.primaryID, entry.connectionID))
                }
            }
        }

        // Resolve in parallel. With bookmarks aggregated across multiple
        // connections (multi-library scope), a serial `for await` would gate
        // every connection's network round-trip behind the previous one.
        let captureLibraryID = libraryID
        let resolved: [Audiobook] = await withTaskGroup(of: (Int, Audiobook?).self) { group in
            for (index, id) in identifiers.enumerated() {
                group.addTask {
                    guard let book = try? await ResolveCache.shared.resolve(primaryID: id.primaryID, groupingID: nil, connectionID: id.connectionID) as? Audiobook else {
                        return (index, nil)
                    }
                    if let captureLibraryID, book.id.libraryID != captureLibraryID.libraryID {
                        return (index, nil)
                    }
                    return (index, book)
                }
            }
            var collected: [(Int, Audiobook)] = []
            for await (index, book) in group {
                if let book { collected.append((index, book)) }
            }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }

        withAnimation { audiobooks = resolved }
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
            } else {
                // Always visible — either a "loading" or "unavailable" state.
                // EmptyView() here would look identical to "the section
                // vanished", which is exactly the feedback we're trying to
                // avoid for an explicitly-pinned collection.
                HomeRowContainer(title: fallbackTitle) {
                    if didFail {
                        placeholder(textKey: "home.section.collection.unavailable")
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("loading")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
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
            let item = try await ResolveCache.shared.resolve(itemID)
            if let collection = item as? ItemCollection {
                withAnimation {
                    self.collection = collection
                    self.didFail = false
                }
            } else {
                withAnimation { didFail = true }
            }
        } catch {
            withAnimation { didFail = true }
        }
    }
}
