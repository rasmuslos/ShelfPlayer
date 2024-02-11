//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct PodcastFullListView: View {
    @Default private var episodesFilter: EpisodeSortFilter.Filter
    
    @Default private var episodesSort: EpisodeSortFilter.SortOrder
    @Default private var episodesAscending: Bool
    
    let episodes: [Episode]
    
    init(episodes: [Episode], podcastId: String) {
        self.episodes = episodes
                
        _episodesFilter = .init(.episodesFilter(podcastId: podcastId))
        
        _episodesSort = .init(.episodesSort(podcastId: podcastId))
        _episodesAscending = .init(.episodesAscending(podcastId: podcastId))
    }
    
    @State private var query = ""
    
    private var visibleEpisodes: [Episode] {
        let episodes = EpisodeSortFilter.filterSort(episodes: episodes, filter: episodesFilter, sortOrder: episodesSort, ascending: episodesAscending)
        let query = query.lowercased()
        
        if query == "" {
            return episodes
        }
        
        return episodes.filter { $0.sortName.contains(query) || $0.name.lowercased().contains(query) || ($0.descriptionText?.lowercased() ?? "").contains(query) }
    }
    
    var body: some View {
        List {
            EpisodeSingleList(episodes: visibleEpisodes)
        }
        .listStyle(.plain)
        .navigationTitle("title.episodes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query)
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeSortFilter(filter: $episodesFilter, sortOrder: $episodesSort, ascending: $episodesAscending)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PodcastFullListView(episodes: .init(repeating: [.fixture], count: 7), podcastId: "fixture")
    }
}
