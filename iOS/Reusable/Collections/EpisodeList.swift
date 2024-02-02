//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase

struct EpisodeList: View {
    let episodes: [Episode]
    
    var body: some View {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    EpisodeRow(episode: episode)
                }
                .modifier(SwipeActionsModifier(item: episode))
            }
    }
}

#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: [
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
        .listStyle(.plain)
    }
}
