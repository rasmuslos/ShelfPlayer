//
//  PodcastLatestView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastLatestPanel: View {
    @Environment(\.library) private var library
    
    @State private var failed = false
    @State private var episodes = [Episode]()
    
    var body: some View {
        Group {
            if episodes.isEmpty {
                if failed {
                    ErrorView()
                        .refreshable {
                            fetchItems()
                        }
                } else {
                    LoadingView()
                        .task {
                            fetchItems()
                        }
                        .refreshable {
                            fetchItems()
                        }
                }
            } else {
                List {
                    EpisodeList(episodes: episodes, context: .latest)
                }
                .listStyle(.plain)
                .refreshable {
                    fetchItems()
                }
            }
        }
        .navigationTitle("panel.latest")
        .modifier(PlaybackSafeAreaPaddingModifier())
    }

    private nonisolated func fetchItems() {
        Task {
            guard let library = await library else {
                return
            }
            
            await MainActor.withAnimation {
                failed = false
            }
            
            guard let episodes = try? await ABSClient[library.connectionID].recentEpisodes(from: library.id, limit: 20) else {
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
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastLatestPanel()
    }
    .previewEnvironment()
}
#endif
