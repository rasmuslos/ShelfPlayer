//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase

struct EpisodesLatestList: View {
    let episodes: [Episode]
    
    var body: some View {
        List {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    EpisodeIndependentRow(episode: episode)
                }
                .modifier(SwipeActionsModifier(item: episode))
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        EpisodesLatestList(episodes: [
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
        ])
    }
}
