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
    @State private var episodeFilter = EpisodeFilter.all
    
    @Default private var episodesSort: EpisodeSortOrder
    @Default private var episodesAscending: Bool
    
    let podcast: Podcast
    @State var episodes: [Episode]
    
    init(podcast: Podcast, episodes: [Episode]) {
        self.podcast = podcast
        _episodes = .init(initialValue: episodes)
        
        _episodesSort = .init(.episodesSort(podcastId: podcast.id))
        _episodesAscending = .init(.episodesAscending(podcastId: podcast.id))
    }
    
    private var sorted: [Episode] {
        Episode.filterSort(episodes: episodes, filter: episodeFilter, sortOrder: episodesSort, ascending: episodesAscending)
    }
    
    var body: some View {
        List {
            ForEach(sorted) {
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
        .modifier(NowPlaying.SafeAreaModifier())
        .onReceive(NotificationCenter.default.publisher(for: PlayableItem.downloadStatusUpdatedNotification)) { _ in
            do {
                episodes = try OfflineManager.shared.episodes(podcastId: podcast.id)
            } catch {}
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
