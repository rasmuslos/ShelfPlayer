//
//  EpisodesList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import AudiobooksKit

struct EpisodesList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) { episode in
            NavigationLink(destination: EpisodeView(episode: episode)) {
                EpisodeRow(episode: episode)
            }
            .listRowInsets(.init(top: 5, leading: 15, bottom: 5, trailing: 15))
            .modifier(SwipeActionsModifier(item: episode))
        }
    }
}

#Preview {
    NavigationStack {
        List {
            EpisodesList(episodes: [
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
