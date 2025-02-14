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
import RFVisuals
import ShelfPlayerKit

@Observable @MainActor
final class PodcastViewModel {
    let podcast: Podcast
    
    private(set) var episodes: [Episode]
    private(set) var visible: [Episode]
    
    var filter: ItemFilter {
        didSet {
            Defaults[.episodesFilter(podcast.id)] = filter
            updateVisible()
        }
    }
    
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
    
    var isToolbarVisible: Bool
    var settingsSheetPresented: Bool
    var descriptionSheetPresented: Bool
    
    private(set) var dominantColor: Color?
    
    var search: String
    
    private(set) var notifyError: Bool
    
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        
        self.episodes = episodes
        visible = []
        
        filter = Defaults[.episodesFilter(podcast.id)]
        
        ascending = Defaults[.episodesAscending(podcast.id)]
        sortOrder = Defaults[.episodesSortOrder(podcast.id)]
        
        isToolbarVisible = false
        settingsSheetPresented = false
        descriptionSheetPresented = false
        
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
            var episodes = await episodes
            
            // MARK: Filter
            
            let filter = await filter
            
            if filter != .all {
                var included = [Episode]()
                
                for episode in episodes {
                    if await episode.isIncluded(in: filter) {
                        included.append(episode)
                    }
                }
                
                episodes = included
            }
            
            // MARK: Search
            
            let search = await search.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !search.isEmpty {
                episodes = episodes.filter { $0.sortName.localizedStandardContains(search) || $0.descriptionText?.localizedStandardContains(search) == true }
            }
            
            // MARK: Sort
            
            let sortOrder = await sortOrder
            let ascending = await ascending
            
            episodes.sort { $0.compare(other: $1, sortOrder: sortOrder, ascending: ascending) }
            
            if !ascending {
                episodes.reverse()
            }
            
            // MARK: Update view
            
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
