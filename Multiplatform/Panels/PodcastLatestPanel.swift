//
//  PodcastLatestView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct PodcastLatestPanel: View {
    @Environment(\.library) private var library
    
    @State private var didFail = false
    @State private var isLoading = false
    @State private var episodes = [Episode]()
    
    var body: some View {
        Group {
            if episodes.isEmpty {
                Group {
                    if didFail {
                        ErrorView()
                    } else if isLoading {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                }
                .refreshable {
                    fetchItems()
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
        .task {
            fetchItems()
        }
    }

    private nonisolated func fetchItems() {
        Task {
            guard let library = await library else {
                return
            }
            
            await MainActor.withAnimation {
                didFail = false
                isLoading = true
            }
            
            guard let episodes = try? await ABSClient[library.connectionID].recentEpisodes(from: library.id, limit: 20) else {
                await MainActor.withAnimation {
                    didFail = true
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.isLoading = false
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
