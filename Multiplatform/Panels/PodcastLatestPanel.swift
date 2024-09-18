//
//  PodcastLatestView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct PodcastLatestPanel: View {
    @Environment(\.libraryId) private var libraryID
    
    @State private var failed = false
    @State private var episodes = [Episode]()
    
    var body: some View {
        Group {
            if episodes.isEmpty {
                if failed {
                    ErrorView()
                        .refreshable {
                            await fetchItems()
                        }
                } else {
                    LoadingView()
                        .task {
                            await fetchItems()
                        }
                }
            } else {
                List {
                    EpisodeList(episodes: episodes)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("title.latest")
        .modifier(NowPlaying.SafeAreaModifier())
    }

    private nonisolated func fetchItems() async {
        await MainActor.withAnimation {
            failed = false
        }
        
        guard let episodes = try? await AudiobookshelfClient.shared.recentEpisodes(limit: 20, libraryId: libraryID) else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.episodes = episodes
        }
    }
}

#Preview {
    PodcastLatestPanel()
}
