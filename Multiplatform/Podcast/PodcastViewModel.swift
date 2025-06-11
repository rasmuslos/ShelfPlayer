//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import DefaultsMacros
import ShelfPlayback

@Observable @MainActor
final class PodcastViewModel {
    let podcast: Podcast
    
    private(set) var episodes: [Episode]
    private(set) var visible: [Episode]
    
    var ascending: Bool {
        didSet {
            Defaults[.episodesAscending(podcast.id)] = ascending
            updateVisible()
            requestConvenienceDownload()
        }
    }
    var sortOrder: EpisodeSortOrder {
        didSet {
            Defaults[.episodesSortOrder(podcast.id)] = sortOrder
            updateVisible()
            requestConvenienceDownload()
        }
    }
    
    var filter: ItemFilter {
        didSet {
            Defaults[.episodesFilter(podcast.id)] = filter
            updateVisible()
            requestConvenienceDownload()
        }
    }
    var seasonFilter: String? {
        didSet {
            Defaults[.episodesSeasonFilter(podcast.id)] = seasonFilter
            updateVisible()
            requestConvenienceDownload()
        }
    }
    var restrictToPersisted: Bool {
        didSet {
            Defaults[.episodesFilter(podcast.id)] = filter
            updateVisible()
            requestConvenienceDownload()
        }
    }
    
    var isToolbarVisible: Bool
    
    private(set) var dominantColor: Color?
    
    var search: String
    
    private(set) var notifyError: Bool
    
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        
        self.episodes = episodes
        visible = []
        
        ascending = Defaults[.episodesAscending(podcast.id)]
        sortOrder = Defaults[.episodesSortOrder(podcast.id)]
        
        filter = Defaults[.episodesFilter(podcast.id)]
        seasonFilter = Defaults[.episodesSeasonFilter(podcast.id)]
        restrictToPersisted = Defaults[.episodesRestrictToPersisted(podcast.id)]
        
        isToolbarVisible = false
        
        dominantColor = nil
        
        search = ""
        
        notifyError = false
        
        updateVisible()
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
    
    nonisolated func load(refresh: Bool) {
        Task {
            await withTaskGroup {
                $0.addTask { await self.extractColor() }
                $0.addTask { await self.fetchEpisodes() }
                
                if refresh {
                    $0.addTask {
                        try? await ShelfPlayer.refreshItem(itemID: self.podcast.id)
                        self.load(refresh: false)
                    }
                }
            }
        }
    }
    nonisolated func updateVisible() {
        Task {
            let episodes = await Podcast.filterSort(episodes, filter: filter, seasonFilter: seasonFilter, restrictToPersisted: restrictToPersisted, search: search, sortOrder: sortOrder, ascending: ascending)
            
            await MainActor.withAnimation {
                self.visible = episodes
            }
        }
    }
    
    nonisolated func requestConvenienceDownload() {
        Task {
            await PersistenceManager.shared.convenienceDownload.scheduleUpdate(itemID: podcast.id)
        }
    }
}

private extension PodcastViewModel {
    nonisolated func extractColor() async {
        let color = await PersistenceManager.shared.item.dominantColor(of: podcast.id)
        
        await MainActor.withAnimation {
            self.dominantColor = color
        }
    }
    
    nonisolated func fetchEpisodes() async {
        do {
            let episodes = try await ABSClient[podcast.id.connectionID].episodes(from: podcast.id)
            
            await MainActor.withAnimation {
                self.episodes = episodes
            }
            
            updateVisible()
        } catch {
            await MainActor.run {
                notifyError.toggle()
            }
        }
    }
}
