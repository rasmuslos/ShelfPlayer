//
//  PodcastViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import Defaults
import RFKVisuals
import ShelfPlayerKit

@Observable
internal final class PodcastViewModel {
    @MainActor let podcast: Podcast
    @MainActor private(set) var episodes: [Episode]
    
    @MainActor var libraryID: String!
    
    @MainActor var dominantColor: Color?
    
    @MainActor var toolbarVisible: Bool
    @MainActor var settingsSheetPresented: Bool
    
    @MainActor var filter: EpisodeFilter {
        didSet {
            Defaults[.episodesFilter(podcastId: podcast.id)] = filter
        }
    }
    
    @MainActor var ascending: Bool {
        didSet {
            Defaults[.episodesAscending(podcastId: podcast.id)] = ascending
        }
    }
    @MainActor var sortOrder: EpisodeSortOrder {
        didSet {
            Defaults[.episodesSort(podcastId: podcast.id)] = sortOrder
        }
    }
    
    @MainActor var search: String
    @MainActor var fetchConfiguration: PodcastFetchConfiguration
    
    @MainActor private var errorNotify: Bool
    
    @MainActor
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        self.episodes = episodes
        
        dominantColor = nil
        
        toolbarVisible = false
        settingsSheetPresented = false
        
        filter = Defaults[.episodesFilter(podcastId: podcast.id)]
        
        ascending = Defaults[.episodesAscending(podcastId: podcast.id)]
        sortOrder = Defaults[.episodesSort(podcastId: podcast.id)]
        
        search = ""
        fetchConfiguration = OfflineManager.shared.requireConfiguration(podcastId: podcast.id)
        
        errorNotify = false
    }
}

internal extension PodcastViewModel {
    @MainActor
    var visible: [Episode] {
        return Array(Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending).prefix(15))
    }
    @MainActor
    var filtered: [Episode] {
        let search = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        if search.isEmpty {
            return sorted
        }
        
        return sorted.filter { $0.sortName.localizedStandardContains(search) || $0.descriptionText?.localizedStandardContains(search) == true }
    }
    
    @MainActor
    var episodeCount: Int {
        guard !episodes.isEmpty else {
            return podcast.episodeCount
        }
        
        return episodes.count
    }
    
    @MainActor
    var settingsIcon: String {
        guard fetchConfiguration.autoDownload else {
            return "gear"
        }
        
        if fetchConfiguration.notifications {
            return "gear.badge"
        }
        
        return "gear.badge.checkmark"
    }
    
    @MainActor
    func queue(for episode: Episode) -> [Episode] {
        guard let index = episodes.firstIndex(of: episode) else {
            return []
        }
        
        return Array(episodes[index..<episodes.endIndex])
    }
    
    func load() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask { await self.fetchEpisodes() }
            $0.addTask { await self.extractColor() }
            
            await $0.waitForAll()
        }
    }
}

private extension PodcastViewModel {
    func fetchEpisodes() async {
        guard let episodes = try? await AudiobookshelfClient.shared.episodes(podcastId: podcast.id) else {
            await MainActor.run {
                errorNotify.toggle()
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.episodes = episodes
        }
    }
    
    func extractColor() async {
        guard let image = await podcast.cover?.systemImage else {
            return
        }
        
        guard let colors = try? await RFKVisuals.extractDominantColors(4, image: image), let result = RFKVisuals.determineMostSaturated(colors.map { $0.color }) else {
            return
        }
        
        await MainActor.withAnimation {
            self.dominantColor = result
        }
    }
}
