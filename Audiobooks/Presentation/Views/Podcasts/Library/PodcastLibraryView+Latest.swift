//
//  PodcastLibraryView+Latest.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct LatestView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var episodes = [Episode]()
        
        var body: some View {
            NavigationStack {
                Group {
                    if failed {
                        ErrorView()
                    } else if episodes.isEmpty {
                        LoadingView()
                    } else {
                        LatestList(episodes: episodes)
                            .modifier(NowPlayingBarSafeAreaModifier())
                    }
                }
                .navigationTitle("Latest Episodes")
                .navigationBarTitleDisplayMode(.large)
                .task(fetchEpisodes)
                .refreshable(action: fetchEpisodes)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Latest", systemImage: "clock")
            }
        }
    }
}

// MARK: Helper

extension PodcastLibraryView.LatestView {
    @Sendable
    func fetchEpisodes() {
        Task.detached {
            if let episodes = try? await AudiobookshelfClient.shared.getLatestEpisodes(libraryId: libraryId) {
                self.episodes = episodes
            } else {
                failed = true
            }
        }
    }
}
