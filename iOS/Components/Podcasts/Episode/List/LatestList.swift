//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import AudiobooksKit

struct LatestList: View {
    let episodes: [Episode]
    
    var body: some View {
        List {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    EpisodeImageRow(episode: episode)
                }
                .modifier(SwipeActionsModifier(item: episode))
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        LatestList(episodes: [
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
