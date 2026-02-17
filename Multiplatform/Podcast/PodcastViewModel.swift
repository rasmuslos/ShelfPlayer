//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class PodcastViewModel: Equatable, Hashable {
    let podcast: Podcast
    
    private(set) var episodes: [Episode]
    private(set) var visible: [Episode]
    
    private(set) var channelPodcasts = [Podcast]()
    
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
    
    var search: String
    var isToolbarVisible: Bool
    
    private(set) var dominantColor: Color?
    private(set) var notifyError: Bool
    
    init(podcast: Podcast) {
        self.podcast = podcast
        
        episodes = []
        visible = []
        
        search = ""
        isToolbarVisible = false
        
        dominantColor = nil
        notifyError = false
    }
    
    static func == (lhs: PodcastViewModel, rhs: PodcastViewModel) -> Bool {
        lhs === rhs
    }
    func hash(into hasher: inout Hasher) {
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
            
            let episodes = await Podcast.filterSort(episodes, filter: filter!, seasonFilter: seasonFilter, restrictToPersisted: restrictToPersisted!, search: search, sortOrder: sortOrder!, ascending: ascending!)
            
            withAnimation {
                self.visible = episodes
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
    
    func fetchEpisodes() async {
        #if DEBUG && false
        self.episodes = .init(repeating: .fixture, count: 1)

        updateVisible()
        return
        #endif
        
        do {
            let episodes = try await ABSClient[podcast.id.connectionID].podcast(with: podcast.id).1
            
            withAnimation {
                self.episodes = episodes
            }
            
            updateVisible()
        } catch {
            notifyError.toggle()
        }
    }
}
