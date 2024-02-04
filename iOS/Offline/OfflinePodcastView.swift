//
//  OfflinePodcastView.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPBase

struct OfflinePodcastView: View {
    let podcast: Podcast
    let episodes: [Episode]
    
    var body: some View {
        List {
            ForEach(episodes) {
                EpisodeSingleList.EpisodeRow(episode: $0)
            }
        }
        .contentMargins(5)
        .listStyle(.plain)
        .navigationTitle(podcast.name)
    }
}

#Preview {
    NavigationStack {
        OfflinePodcastView(podcast: .fixture, episodes: .init(repeating: [.fixture], count: 7))
    }
}
