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
    
    private var relevantItemIDs: [ItemIdentifier] {
        episodes.flatMap(\.itemIDs)
    }
    
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
            }
        }
        .navigationTitle(library?.name ?? String(localized: "error.unavailable"))
        .sensoryFeedback(.error, trigger: didFail)
        .toolbar {
            if horizontalSizeClass == .compact {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ListenNowSheetToggle()
                    
                    Menu("navigation.library.select", systemImage: "books.vertical.fill") {
                        LibraryPicker()
                    }
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
        .onReceive(RFNotification[.progressEntityUpdated].publisher()) { (connectionID, primaryID, groupingID, entity) in
            guard relevantItemIDs.contains(where: {
                $0.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID)
                || (entity?.progress ?? 0) > 0
            }) else {
                return
            }
            
            fetchItems()
        }
    }
}

private extension PodcastHomePanel {
    nonisolated func fetchItems() {
        Task {
            await MainActor.withAnimation {
                didFail = false
                isLoading = true
            }
            
            await withTaskGroup {
                $0.addTask { await fetchRemoteItems() }
            }
            
            await MainActor.withAnimation {
                isLoading = false
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
