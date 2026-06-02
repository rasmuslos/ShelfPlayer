//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import Combine
import OSLog
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class PodcastViewModel: Equatable, Hashable {
    private let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "PodcastViewModel")

    private var observerSubscriptions = Set<AnyCancellable>()

    let podcast: Podcast

    private(set) var episodes = [Episode]()
    private(set) var visible = [Episode]()

    private(set) var playNowEpisode: Episode? = .placeholder

    private(set) var channelPodcasts = [Podcast]()

    private(set) var explore = [Podcast]()

    var bulkSelected: [ItemIdentifier]? = nil
    private(set) var performingBulkAction = false

    var ascending: Bool?
    var sortOrder: EpisodeSortOrder?

    var filter: ItemFilter?
    var seasonFilter: String? {
        didSet {
            self.updateVisible()
            self.requestConvenienceDownload()
            self.storeFilterSort()
        }
    }
    var restrictToPersisted: Bool?

    var search = ""
    var isToolbarVisible = false

    private(set) var dominantColor: Color?
    private(set) var notifyError = false

    init(_ podcast: Podcast) {
        self.podcast = podcast

        ItemEventSource.shared.updated
            .sink { [weak self] connectionID, primaryID, groupingID in
                Task { @MainActor [weak self] in
                    guard let self, self.podcast.id.matchesItemUpdate(connectionID: connectionID, primaryID: primaryID, groupingID: groupingID) else {
                        return
                    }

                    self.load(refresh: true)
                }
            }
            .store(in: &observerSubscriptions)
    }

    nonisolated static func == (lhs: PodcastViewModel, rhs: PodcastViewModel) -> Bool {
        lhs === rhs
    }
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(podcast.id)
    }
}

extension PodcastViewModel {
    var ascendingBinding: Binding<Bool> {
        .init() {
            self.ascending ?? false
        } set: {
            self.updateVisible()
            self.requestConvenienceDownload()

            self.ascending = $0

            self.storeFilterSort()
        }
    }
    var sortOrderBinding: Binding<EpisodeSortOrder> {
        .init() {
            self.sortOrder ?? .index
        } set: {
            self.updateVisible()
            self.requestConvenienceDownload()

            self.sortOrder = $0

            self.storeFilterSort()
        }
    }
    var filterBinding: Binding<ItemFilter> {
        .init() {
            self.filter ?? .notFinished
        } set: {
            self.updateVisible()
            self.requestConvenienceDownload()

            self.filter = $0

            self.storeFilterSort()
        }
    }
    var restrictToPersistedBinding: Binding<Bool> {
        .init() {
            self.restrictToPersisted ?? false
        } set: {
            self.updateVisible()
            self.requestConvenienceDownload()

            self.restrictToPersisted = $0

            self.storeFilterSort()
        }
    }
}

extension PodcastViewModel {
    var preview: [Episode] {
        Array(visible.prefix(17))
    }

    var episodeCount: Int {
        guard !episodes.isEmpty else {
            return podcast.episodeCount
        }

        return episodes.count
    }

    var seasons: [String] {
        var seasons = Set<String>()

        for episode in episodes where episode.index.season != nil {
            seasons.insert(episode.index.season!)
        }

        if let seasonFilter, !seasons.contains(seasonFilter) {
            self.seasonFilter = nil
        }

        guard seasons.count > 1 else {
            if self.seasonFilter != nil {
                self.seasonFilter = nil
            }

            return []
        }

        return seasons.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    func seasonLabel(of season: String) -> String {
        if season.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(localized: "item.season.noLabel")
        }

        if let number = Int(season) {
            return String(localized: "item.season \(number)")
        }

        return season
    }

    private func performBulk(_ next: @Sendable @escaping ([ItemIdentifier]) async throws -> Void) {
        Task {
            guard !performingBulkAction else {
                return
            }

            performingBulkAction = true

            if let bulkSelected = bulkSelected {
                do {
                    try await next(bulkSelected)
                } catch {
                    notifyError.toggle()
                }
            }

            withAnimation {
                performingBulkAction = false
                bulkSelected = nil
            }
        }
    }
    func performBulkQueue() {
        performBulk {
            try await AudioPlayer.shared.queue($0.map { .init(itemID: $0, origin: .podcast(self.podcast.id)) })
        }
    }
    func performBulkAction(isFinished: Bool) {
        performBulk {
            for itemID in $0 {
                if isFinished {
                    try await PersistenceManager.shared.progress.markAsCompleted(itemID)
                } else {
                    try await PersistenceManager.shared.progress.markAsListening(itemID)
                }
            }
        }
    }
    func performBulkAction(download: Bool) {
        performBulk {
            for itemID in $0 {
                if download {
                    try await PersistenceManager.shared.download.download(itemID)
                } else {
                    try await PersistenceManager.shared.download.remove(itemID)
                }
            }
        }
    }

    func load(refresh: Bool) {
        Task {
            await withTaskGroup {
                $0.addTask { await self.extractColor() }
                $0.addTask { await self.fetchEpisodes() }

                if refresh || explore.isEmpty {
                    $0.addTask { await self.loadExplore() }
                }
                if refresh || channelPodcasts.isEmpty {
                    $0.addTask { await self.loadChannel() }
                }
            }

            if refresh {
                try? await ShelfPlayer.refreshItem(itemID: self.podcast.id)
                self.load(refresh: false)
            }
        }
    }
    func updateVisible() {
        Task {
            if ascending == nil {
                let configuration = await PersistenceManager.shared.item.podcastFilterSortConfiguration(for: podcast.id)

                ascending = configuration.ascending
                sortOrder = configuration.sortOrder
                filter = configuration.filter
                seasonFilter = configuration.seasonFilter
                restrictToPersisted = configuration.restrictToPersisted
            }

            logger.debug("Updating visible episodes; sort: \(String(describing: self.sortOrder), privacy: .public) ascending: \(self.ascending ?? false, privacy: .public) filter: \(String(describing: self.filter), privacy: .public)")

            let episodes = await Podcast.filterSort(episodes, filter: filter!, seasonFilter: seasonFilter, restrictToPersisted: restrictToPersisted!, search: search, sortOrder: sortOrder!, ascending: ascending!)

            withAnimation {
                self.visible = episodes
                self.playNowEpisode = episodes.first
            }
        }
    }
}

private extension PodcastViewModel {
    func requestConvenienceDownload() {
        Task {
            await PersistenceManager.shared.convenienceDownload.scheduleUpdate(itemID: podcast.id)
        }
    }
    func storeFilterSort() {
        guard let sortOrder, let ascending, let filter, let restrictToPersisted else {
            return
        }

        Task.detached {
            try await PersistenceManager.shared.item.setPodcastFilterSortConfiguration(.init(sortOrder: sortOrder, ascending: ascending, filter: filter, restrictToPersisted: restrictToPersisted, seasonFilter: self.seasonFilter), for: self.podcast.id)
        }
    }

    func extractColor() async {
        let color = await PersistenceManager.shared.item.dominantColor(of: podcast.id)

        withAnimation {
            self.dominantColor = color
        }
    }

    /// Random sample of podcasts from this podcast's library, used to surface
    /// other things the user might enjoy. Pull-to-refresh reshuffles because
    /// the underlying `sort=random` API call already bypasses the API cache.
    /// Asking for 11 keeps us at 10 even after dropping the current podcast.
    func loadExplore() async {
        #if DEBUG
        if podcast.id.libraryID == "fixture" {
            return
        }
        #endif

        do {
            let casts = try await ABSClient[podcast.id.connectionID].podcastsRandom(from: podcast.id.libraryID, limit: 11)
            // Drop the current podcast and any fully-finished ones (no incomplete episodes left to discover).
            let filtered = casts.filter { $0.id != podcast.id && ($0.incompleteEpisodeCount ?? -1) != 0 }.prefix(10)

            withAnimation {
                self.explore = Array(filtered)
            }
        } catch {
            logger.warning("Failed to load explore podcasts for \(self.podcast.id, privacy: .public): \(error, privacy: .public)")
        }
    }

    /// Other podcasts on the same channel — i.e. by the same author. Surfaced
    /// as a row next to "Explore". Resolved through the regular library search
    /// (see ``APIClient/channel(with:)``), not a full-library scan.
    func loadChannel() async {
        #if DEBUG
        if podcast.id.libraryID == "fixture" {
            return
        }
        #endif

        guard let author = podcast.authors.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return
        }

        do {
            let channelID = Channel.convertNameToID(author, libraryID: podcast.id.libraryID, connectionID: podcast.id.connectionID)
            let channel = try await ABSClient[podcast.id.connectionID].channel(with: channelID)
            let siblings = channel.podcasts.filter { $0.id != podcast.id }

            withAnimation {
                self.channelPodcasts = siblings
            }
        } catch {
            logger.warning("Failed to load channel podcasts for \(self.podcast.id, privacy: .public): \(error, privacy: .public)")
        }
    }

    func fetchEpisodes() async {
        #if DEBUG
        if podcast.id.libraryID == "fixture" {
            self.episodes = .init(repeating: .fixture, count: 1)
            updateVisible()

            return
        }
        #endif

        logger.info("Loading episodes for podcast \(self.podcast.id, privacy: .public)")

        do {
            episodes = try await ABSClient[podcast.id.connectionID].podcast(with: podcast.id).1
            updateVisible()
        } catch {
            logger.warning("Failed to load episodes for \(self.podcast.id, privacy: .public): \(error, privacy: .public)")
            notifyError.toggle()
        }
    }
}
