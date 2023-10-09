//
//  EpisodesList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodesList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) { episode in
            NavigationLink(destination: EpisodeView(episode: episode)) {
                EpisodeListRow(episode: episode)
            }
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
