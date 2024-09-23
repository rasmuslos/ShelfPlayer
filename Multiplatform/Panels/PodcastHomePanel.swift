//
//  PodcastListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct PodcastHomePanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.hideFromContinueListening) private var hideFromContinueListening
    
    @State private var episodes = [HomeRow<Episode>]()
    @State private var podcasts = [HomeRow<Podcast>]()
    
    @State private var failed = false
    
    var body: some View {
        Group {
            if episodes.isEmpty && podcasts.isEmpty {
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
                        .refreshable {
                            await fetchItems()
                        }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(episodes) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.label)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 20)
                                
                                if row.id == "continue-listening" {
                                    EpisodeFeaturedGrid(episodes: row.entities.filter { episode in
                                        !hideFromContinueListening.contains { $0.itemId == episode.podcastId && $0.episodeId == episode.id }
                                    })
                                } else {
                                    EpisodeGrid(episodes: row.entities)
                                }
                            }
                        }
                        
                        ForEach(podcasts) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.label)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 20)
                                
                                PodcastHGrid(podcasts: row.entities)
                            }
                        }
                    }
                }
                .refreshable {
                    await fetchItems()
                }
            }
        }
        .navigationTitle("panel.home")
        .modifier(SelectLibraryModifier(isCompact: horizontalSizeClass == .compact))
        .modifier(NowPlaying.SafeAreaModifier())
    }
    
    private nonisolated func fetchItems() async {
        await MainActor.withAnimation {
            failed = false
        }
        
        do {
            let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await AudiobookshelfClient.shared.home(libraryID: library.id)
            
            await MainActor.withAnimation {
                self.episodes = home.1
                self.podcasts = home.0
            }
        } catch {
            await MainActor.withAnimation {
                failed = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PodcastHomePanel()
            .environment(NowPlaying.ViewModel())
    }
}
