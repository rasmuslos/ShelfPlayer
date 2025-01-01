//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import Defaults
import RFVisuals
import ShelfPlayerKit

@Observable @MainActor
internal final class PodcastViewModel {
    let podcast: Podcast
    var episodes: [Episode]
    
    var library: Library!
    
    var dominantColor: Color?
    var toolbarVisible: Bool
    
    var settingsSheetPresented: Bool
    var descriptionSheetPresented: Bool
    
    var filter: ItemFilter {
        didSet {
            Defaults[.groupingFilter(podcast.id)] = filter
        }
    }
    
    var ascending: Bool {
        didSet {
            Defaults[.groupingAscending(podcast.id)] = ascending
        }
    }
    var sortOrder: EpisodeSortOrder {
        didSet {
            Defaults[.groupingSortOrder(podcast.id)] = sortOrder
        }
    }
    
    var search: String
    var downloadConfiguration: PersistenceManager.PodcastSubsystem.PodcastAutoDownloadConfiguration?
    
    var errorNotify: Bool
    
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        self.episodes = episodes
        
        dominantColor = nil
        toolbarVisible = false
        
        settingsSheetPresented = false
        descriptionSheetPresented = false
        
        filter = Defaults[.groupingFilter(podcast.id)]
        
        ascending = Defaults[.groupingAscending(podcast.id)]
        sortOrder = Defaults[.groupingSortOrder(podcast.id)]
        
        search = ""
        
        errorNotify = false
    }
}

internal extension PodcastViewModel {
    var visible: [Episode] {
        return Array(Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending).prefix(15))
    }
    var filtered: [Episode] {
        let search = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        if search.isEmpty {
            return sorted
        }
        
        return sorted.filter { $0.sortName.localizedStandardContains(search) || $0.descriptionText?.localizedStandardContains(search) == true }
    }
    
    var episodeCount: Int {
        guard !episodes.isEmpty else {
            return podcast.episodeCount
        }
        
        return episodes.count
    }
    
    var settingsIcon: String {
        if downloadConfiguration?.enableNotifications == true {
            "gear.badge"
        } else if downloadConfiguration?.enabled == true {
            "gear.badge.checkmark"
        } else {
            "gear.badge.xmark"
        }
    }
    
    nonisolated func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.extractColor() }
            $0.addTask { await self.fetchEpisodes() }
            $0.addTask { await self.fetchDownloadConfiguration() }
            
            await $0.waitForAll()
        }
    }
}

private extension PodcastViewModel {
    nonisolated func extractColor() async {
        guard let image = await podcast.cover?.platformImage else {
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
        guard let episodes = try? await ABSClient[podcast.id.serverID].episodes(from: podcast.id) else {
            await MainActor.run {
                errorNotify.toggle()
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.episodes = episodes
        }
    }
    
    nonisolated func fetchDownloadConfiguration() async {
        let configuration = await PersistenceManager.shared.podcasts[podcast.id]
        
        await MainActor.withAnimation {
            self.downloadConfiguration = configuration
        }
    }
}
