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
    
    @State var filter: EpisodeFilter.Filter {
        didSet {
            EpisodeFilter.setFilter(filter, podcastId: podcastId)
        }
    }
    @State var sortOrder: EpisodeFilter.SortOrder {
        didSet {
            EpisodeFilter.setSortOrder(sortOrder, podcastId: podcastId)
        }
    }
    @State var ascending: Bool {
        didSet {
            EpisodeFilter.setAscending(ascending, podcastId: podcastId)
        }
    }
    
    init(episodes: [Episode], podcastId: String) {
        self.episodes = episodes
        self.podcastId = podcastId
        
        filter = EpisodeFilter.getFilter(podcastId: podcastId)
        sortOrder = EpisodeFilter.getSortOrder(podcastId: podcastId)
        ascending = EpisodeFilter.getAscending(podcastId: podcastId)
    }
    
    var body: some View {
        List {
            EpisodesList(episodes: EpisodeFilter.sortEpisodes(EpisodeFilter.filterEpisodes(episodes, filter: filter), sortOrder: sortOrder, ascending: ascending))
        }
        .listStyle(.plain)
        .navigationTitle("Episodes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(EpisodeFilter.Filter.allCases, id: \.hashValue) { filterCase in
                        Button {
                            withAnimation {
                                filter = filterCase
                            }
                        } label: {
                            if filterCase == filter {
                                Label(filterCase.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filterCase.rawValue)
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(EpisodeFilter.SortOrder.allCases, id: \.hashValue) { sortCase in
                        Button {
                            withAnimation {
                                sortOrder = sortCase
                            }
                        } label: {
                            if sortCase == sortOrder {
                                Label(sortCase.rawValue, systemImage: "checkmark")
                            } else {
                                Text(sortCase.rawValue)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        ascending.toggle()
                    } label: {
                        if ascending {
                            Label("Ascending", systemImage: "checkmark")
                        } else {
                            Text("Ascending")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                }
            }
        }
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
