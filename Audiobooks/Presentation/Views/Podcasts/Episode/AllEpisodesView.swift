//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct AllEpisodesView: View {
    let episodes: [Episode]
    let podcastId: String
    
    @State var filter: EpisodeFilterSortMenu.Filter
    @State var sortOrder: EpisodeFilterSortMenu.SortOrder
    @State var ascending: Bool
    
    init(episodes: [Episode], podcastId: String) {
        self.episodes = episodes
        self.podcastId = podcastId
        
        filter = EpisodeFilterSortMenu.getFilter(podcastId: podcastId)
        sortOrder = EpisodeFilterSortMenu.getSortOrder(podcastId: podcastId)
        ascending = EpisodeFilterSortMenu.getAscending(podcastId: podcastId)
    }
    
    var body: some View {
        List {
            EpisodesList(episodes: EpisodeFilterSortMenu.filterAndSortEpisodes(episodes, filter: filter, sortOrder: sortOrder, ascending: ascending))
        }
        .listStyle(.plain)
        .navigationTitle("Episodes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeFilterSortMenu(podcastId: podcastId, filter: $filter, sortOrder: $sortOrder, ascending: $ascending)
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
    }
}

#Preview {
    NavigationStack {
        AllEpisodesView(episodes: [
            .fixture,
            .fixture,
            .fixture,
            .fixture,
            .fixture,
            .fixture,
            .fixture,
        ], podcastId: "fixture")
    }
}
