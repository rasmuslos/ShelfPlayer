//
//  PodcastView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct PodcastView: View {
    @Default(.episodesFilter) private var episodesFilter
    
    @Default(.episodesSort) private var episodesSort
    @Default(.episodesAscending) private var episodesAscending
    
    var podcast: Podcast
    
    @State private var failed = false
    @State private var navigationBarVisible = false
    
    @State private var episodes = [Episode]()
    @State private var imageColors = Item.ImageColors.placeholder
    
    private var visibleEpisodes: [Episode] {
        let episodes = EpisodeSortFilter.filterSort(episodes: episodes, filter: episodesFilter, sortOrder: episodesSort, ascending: episodesAscending)
        return Array(episodes.prefix(15))
    }
    
    var body: some View {
        List {
            Header(podcast: podcast, imageColors: imageColors, navigationBarVisible: $navigationBarVisible)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if episodes.isEmpty {
                if failed {
                    ErrorView()
                        .listRowSeparator(.hidden)
                } else {
                    HStack {
                        Spacer()
                        LoadingView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .padding(.top, 50)
                }
            } else {
                HStack {
                    Text("episodes")
                        .foregroundStyle(.secondary)
                    
                    NavigationLink(destination: PodcastFullListView(episodes: episodes)) {
                        HStack {
                            Spacer()
                            Text("episodes.all")
                        }
                    }
                }
                .padding(.horizontal, 15)
                .frame(height: 45)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                
                EpisodeList(episodes: visibleEpisodes)
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier(podcast: podcast, navigationBarVisible: navigationBarVisible, imageColors: imageColors))
        .modifier(NowPlayingBarSafeAreaModifier())
        .task { await fetchEpisodes() }
        .refreshable { await fetchEpisodes() }
        .task(priority: .background) {
            withAnimation(.spring) {
                imageColors = podcast.getImageColors()
            }
        }
    }
}

// MARK: Helper

extension PodcastView {
    func fetchEpisodes() async {
        failed = false
        
        if let episodes = try? await AudiobookshelfClient.shared.getEpisodes(podcastId: podcast.id) {
            self.episodes = episodes
            podcast.episodeCount = episodes.count
        } else {
            failed = true
        }
    }
}

#Preview {
    NavigationStack {
        PodcastView(podcast: Podcast.fixture)
    }
}
