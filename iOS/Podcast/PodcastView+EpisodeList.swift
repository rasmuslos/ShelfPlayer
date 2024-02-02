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
    @Default(.episodesFilter) private var episodesFilter
    
    @Default(.episodesSort) private var episodesSort
    @Default(.episodesAscending) private var episodesAscending
    
    let episodes: [Episode]
    
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
        PodcastFullListView(episodes: .init(repeating: [.fixture], count: 7))
    }
}
