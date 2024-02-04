//
//  OfflinePodcastView.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import Defaults
import SPBase

struct OfflinePodcastView: View {
    @State private var episodeFilter = EpisodeSortFilter.Filter.all
    
    @Default(.episodesSort) private var episodesSort
    @Default(.episodesAscending) private var episodesAscending
    
    let podcast: Podcast
    let episodes: [Episode]
    
    var body: some View {
        List {
            ForEach(episodes) {
                EpisodeSingleList.EpisodeRow(episode: $0)
                    .modifier(SwipeActionsModifier(item: $0))
            }
        }
        .contentMargins(5)
        .listStyle(.plain)
        .navigationTitle(podcast.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeSortFilter(filter: $episodeFilter, sortOrder: $episodesSort, ascending: $episodesAscending)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OfflinePodcastView(podcast: .fixture, episodes: .init(repeating: [.fixture], count: 7))
    }
}
