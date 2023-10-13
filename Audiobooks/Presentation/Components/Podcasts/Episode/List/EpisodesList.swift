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
                EpisodeRow(episode: episode)
            }
            .listRowInsets(.init(top: 5, leading: 15, bottom: 5, trailing: 15))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if episode.offline == .none {
                    Button {
                        Task {
                            try! await OfflineManager.shared.downloadEpisode(episode)
                        }
                    } label: {
                        Label("Download", systemImage: "arrow.down")
                    }
                    .tint(.green)
                } else if episode.offline == .downloaded {
                    Button(role: .destructive) {
                        try? OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                    } label: {
                        Label("Delete download", systemImage: "trash")
                    }
                }
            }
            // TODO: mark as played
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
