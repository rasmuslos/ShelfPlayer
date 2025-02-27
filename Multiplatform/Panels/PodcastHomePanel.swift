//
//  PodcastListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastHomePanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // @Default(.hideFromContinueListening) private var hideFromContinueListening
    
    @State private var episodes = [HomeRow<Episode>]()
    @State private var podcasts = [HomeRow<Podcast>]()
    
    @State private var failed = false
    
    var body: some View {
        Group {
            if episodes.isEmpty && podcasts.isEmpty {
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(episodes) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.localizedLabel)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 20)
                                
                                if row.id == "continue-listening" {
                                    EpisodeFeaturedGrid(episodes: row.entities)
                                } else {
                                    EpisodeGrid(episodes: row.entities)
                                }
                            }
                        }
                        
                        ForEach(podcasts) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.localizedLabel)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal, 20)
                                
                                PodcastHGrid(podcasts: row.entities)
                            }
                        }
                    }
                }
                .refreshable {
                    fetchItems()
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable.title"))
        .sensoryFeedback(.error, trigger: failed)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("library.change", systemImage: "books.vertical.fill") {
                    LibraryPicker()
                }
            }
        }
        .onReceive(RFNotification[.playbackStopped].publisher()) {
            fetchItems()
        }
        // .modifier(NowPlaying.SafeAreaModifier())
    }
}

private extension PodcastHomePanel {
    nonisolated func fetchItems() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            await withTaskGroup(of: Void.self) {
                $0.addTask { await fetchRemoteItems() }
            }
        }
    }
    nonisolated func fetchRemoteItems() async {
        guard let library = await library else {
            return
        }
        
        do {
            let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[library.connectionID].home(for: library.id)
            let episodes = await HomeRow.prepareForPresentation(home.1, connectionID: library.connectionID)
            
            await MainActor.withAnimation {
                self.episodes = episodes
                podcasts = home.0
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
    }
    .previewEnvironment()
}
