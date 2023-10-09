//
//  PodcastView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct PodcastView: View {
    let podcast: Podcast
    
    @State var navbarVisible = false
    @State var failed = false
    
    @State var filter: EpisodeFilter.Filter?
    @State var episodes: [Episode]?
    
    var body: some View {
        List {
            Header(podcast: podcast, navbarVisible: $navbarVisible)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if failed {
                ErrorView()
                    .listRowSeparator(.hidden)
            } else if let episodes = episodes, let filter = filter {
                HStack {
                    EpisodeFilter(podcastId: podcast.id, filter: $filter)
                    Spacer()
                    NavigationLink(destination: AllEpisodesView(episodes: episodes, podcastId: podcast.id)) {
                        HStack {
                            Spacer()
                            Text("See all")
                        }
                    }
                }
                .padding(.horizontal)
                .frame(height: 45)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                
                EpisodesList(episodes: Array(EpisodeFilter.sortEpisodes(EpisodeFilter.filterEpisodes(episodes, filter: filter), sortOrder: EpisodeFilter.getSortOrder(podcastId: podcast.id), ascending: EpisodeFilter.getAscending(podcastId: podcast.id)) .prefix(15)))
            } else {
                HStack {
                    Spacer()
                    LoadingView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .padding(.top, 50)
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier(podcast: podcast, navbarVisible: $navbarVisible))
        .task(fetchEpisodes)
        .refreshable(action: fetchEpisodes)
    }
}

// MARK: Helper

extension PodcastView {
    @Sendable
    func fetchEpisodes() {
        filter = EpisodeFilter.getFilter(podcastId: podcast.id)
        failed = false
        
        Task.detached {
            if let episodes = try? await AudiobookshelfClient.shared.getPodcastEpisodes(podcastId: podcast.id) {
                self.episodes = episodes
            } else {
                failed = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PodcastView(podcast: Podcast.fixture)
    }
}
