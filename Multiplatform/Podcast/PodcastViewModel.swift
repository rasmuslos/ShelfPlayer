//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import Defaults
import DefaultsMacros
import ShelfPlayerKit

@Observable @MainActor
final class PodcastViewModel {
    let podcast: Podcast
    
    private(set) var episodes: [Episode]
    private(set) var visible: [Episode]
    
    var ascending: Bool {
        didSet {
            Defaults[.episodesAscending(podcast.id)] = ascending
            updateVisible()
        }
    }
    var sortOrder: EpisodeSortOrder {
        didSet {
            Defaults[.episodesSortOrder(podcast.id)] = sortOrder
            updateVisible()
        }
    }
    
    var filter: ItemFilter {
        didSet {
            Defaults[.episodesFilter(podcast.id)] = filter
            updateVisible()
        }
    }
    var seasonFilter: String? {
        didSet {
            Defaults[.episodesSeasonFilter(podcast.id)] = seasonFilter
            updateVisible()
        }
    }
    
    var isToolbarVisible: Bool
    var isConfigureSheetPresented: Bool
    var isDescriptionSheetPresented: Bool
    
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
        
        isToolbarVisible = false
        isConfigureSheetPresented = false
        isDescriptionSheetPresented = false
        
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
            return String(localized: "season.noLabel")
        }
        
        if let number = Int(season) {
            return String(localized: "season \(number)")
        }
        
        return season
    }
    
    nonisolated func load() {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.extractColor() }
                $0.addTask { await self.fetchEpisodes() }
                
                await $0.waitForAll()
            }
        }
    }
}

private extension PodcastViewModel {
    nonisolated func updateVisible() {
        Task {
            let episodes = await Podcast.filterSort(episodes, seasonFilter: seasonFilter, filter: filter, search: search, sortOrder: sortOrder, ascending: ascending)
            
            await MainActor.withAnimation {
                self.visible = episodes
            }
        }
    }
    
    nonisolated func extractColor() async {
        guard let image = await podcast.id.platformCover(size: .small) else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
            return
        }
        
        let filtered = RFKVisuals.brightnessExtremeFilter(colors.map { $0.color }, threshold: 0.1)
        
        guard let result = RFKVisuals.determineMostSaturated(filtered) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
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
