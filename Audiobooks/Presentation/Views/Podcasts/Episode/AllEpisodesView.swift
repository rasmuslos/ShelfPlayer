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
    
    @State var query = ""
    
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
            EpisodesList(episodes: EpisodeFilterSortMenu.filterAndSortEpisodes(episodes, filter: filter, sortOrder: sortOrder, ascending: ascending).filter {
                let query = query.lowercased()
                return query == "" || $0.sortName.contains(query) || $0.name.lowercased().contains(query) || ($0.descriptionText?.lowercased() ?? "").contains(query)
            })
        }
        .listStyle(.plain)
        .navigationTitle("Episodes")
        .searchable(text: $query)
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
