//
//  PodcastListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct PodcastHomePanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var episodes = [HomeRow<Episode>]()
    @State private var podcasts = [HomeRow<Podcast>]()
    
    @State private var didFail = false
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if episodes.isEmpty && podcasts.isEmpty {
                if didFail {
                    ErrorView()
                } else if isLoading {
                    LoadingView()
                } else {
                    EmptyCollectionView()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(episodes) { row in
                            VStack(alignment: .leading, spacing: 0) {
                                RowTitle(title: row.localizedLabel)
                                    .padding(.bottom, 12)
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
                                    .padding(.bottom, 12)
                                    .padding(.horizontal, 20)
                                
                                PodcastHGrid(podcasts: row.entities)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .largeTitleDisplayMode()
        .hapticFeedback(.error, trigger: didFail)
        .toolbar {
            if horizontalSizeClass == .compact {
                ListenNowSheetToggle.toolbarItem()
                
                ToolbarItem(placement: .topBarTrailing) {
                    CompactLibraryPicker(customizeLibrary: true)
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .task {
            fetchItems()
        }
        .refreshable {
            fetchItems()
            ListenedTodayTracker.shared.refresh()
        }
        .onReceive(RFNotification[.playbackReported].publisher()) { _ in
            fetchItems()
        }
    }
}

private extension PodcastHomePanel {
    func fetchItems() {
        Task {
            withAnimation {
                didFail = false
                isLoading = true
            }
            
            await withTaskGroup {
                $0.addTask { await fetchRemoteItems() }
            }
            
            withAnimation {
                isLoading = false
            }
        }
    }
    func fetchRemoteItems() async {
        guard let library = library else {
            return
        }
        
        do {
            let home: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID)
            let episodes = await HomeRow.prepareForPresentation(home.1, connectionID: library.id.connectionID)
            
            withAnimation {
                self.episodes = episodes
                podcasts = home.0
            }
        } catch {
            withAnimation {
                didFail = true
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastHomePanel()
    }
    .previewEnvironment()
}
#endif
