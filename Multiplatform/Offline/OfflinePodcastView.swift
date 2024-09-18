//
//  OfflinePodcastView.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct OfflinePodcastView: View {
    @Default private var episodesAscending: Bool
    @Default private var episodesSortOrder: EpisodeSortOrder
    
    @Default private var episodeFilter: EpisodeFilter
    
    let podcast: Podcast
    @State var episodes: [Episode]
    
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        _episodes = .init(initialValue: episodes)
        
        _episodesSortOrder = .init(.episodesSort(podcastId: podcast.id))
        _episodesAscending = .init(.episodesAscending(podcastId: podcast.id))
        
        _episodeFilter = .init(.episodesFilter(podcastId: podcast.id))
    }
    
    private var sorted: [Episode] {
        Episode.filterSort(episodes: episodes, filter: episodeFilter, sortOrder: episodesSortOrder, ascending: episodesAscending)
    }
    
    var body: some View {
        List {
            EpisodeSingleList(episodes: sorted)
        }
        .listStyle(.plain)
        .navigationTitle(podcast.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeSortFilter(filter: $episodeFilter, sortOrder: $episodesSortOrder, ascending: $episodesAscending)
            }
        }
        .modifier(NowPlaying.SafeAreaModifier())
        .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
            fetchEpisodes()
        }
    }
    
    private nonisolated func fetchEpisodes() {
        Task {
            guard let episodes = try? await OfflineManager.shared.episodes(podcastId: podcast.id) else {
                return
            }
         
            await MainActor.withAnimation {
                self.episodes = episodes
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        OfflinePodcastView(podcast: .fixture, episodes: .init(repeating: [.fixture], count: 7))
    }
}
#endif
