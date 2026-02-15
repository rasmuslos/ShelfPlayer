//
//  PodcastLatestView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
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
                    EpisodeList(episodes: episodes, context: .latest, selected: .constant(nil))
                }
                .listStyle(.plain)
                .refreshable {
                    fetchItems()
                }
            }
        }
        .navigationTitle("panel.latest")
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .task {
            fetchItems()
        }
    }

    private func fetchItems() {
        Task {
            guard let library = library else {
                return
            }
            
            withAnimation {
                didFail = false
                isLoading = true
            }
            
            guard let episodes = try? await ABSClient[library.id.connectionID].recentEpisodes(from: library.id.libraryID, limit: 20) else {
                withAnimation {
                    didFail = true
                }
                
                return
            }
            
            withAnimation {
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
