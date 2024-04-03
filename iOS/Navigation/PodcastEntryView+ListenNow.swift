//
//  PodcastLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import Defaults
import SPBase

extension PodcastEntryView {
    struct ListenNowView: View {
        @Environment(\.libraryId) private var libraryId: String
        @Default(.hideFromContinueListening) private var hideFromContinueListening
        
        @State var episodeRows = [EpisodeHomeRow]()
        @State var podcastRows = [PodcastHomeRow]()
        
        @State var failed = false
        
        var body: some View {
            NavigationStack {
                Group {
                    if episodeRows.isEmpty && podcastRows.isEmpty {
                        if failed {
                            ErrorView()
                        } else {
                            LoadingView()
                                .padding(.top, 50)
                                .task{ await fetchItems() }
                        }
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(episodeRows) { row in
                                    VStack(alignment: .leading) {
                                        RowTitle(title: row.label)
                                        
                                        if row.id == "continue-listening" {
                                            EpisodeFeaturedGrid(episodes: row.episodes.filter { episode in
                                                !hideFromContinueListening.contains { $0.itemId == episode.podcastId && $0.episodeId == episode.id }
                                            })
                                        } else {
                                            EpisodeGrid(episodes: row.episodes)
                                        }
                                    }
                                }
                                
                                ForEach(podcastRows) { row in
                                    VStack(alignment: .leading) {
                                        RowTitle(title: row.label)
                                        PodcastHGrid(podcasts: row.podcasts)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("title.listenNow")
                .modifier(LibrarySelectorModifier())
                .modifier(NowPlayingBarSafeAreaModifier())
                .refreshable { await fetchItems() }
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.home", systemImage: "waveform")
            }
        }
    }
}

extension PodcastEntryView.ListenNowView {
    func fetchItems() async {
        failed = false
        
        do {
            (episodeRows, podcastRows) = try await AudiobookshelfClient.shared.getPodcastsHome(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}
