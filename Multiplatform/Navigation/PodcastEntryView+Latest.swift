//
//  PodcastLibraryView+Latest.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

extension PodcastEntryView {
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
                        List {
                            EpisodeList(episodes: episodes)
                        }
                        .listStyle(.plain)
                        .modifier(NowPlayingBarSafeAreaModifier())
                    }
                }
                .navigationTitle("title.latest")
                .task{ await fetchItems() }
                .refreshable{ await fetchItems() }
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.latest", systemImage: "clock")
            }
        }
    }
}

extension PodcastEntryView.LatestView {
    func fetchItems() async {
        failed = false
        
        do {
            episodes = try await AudiobookshelfClient.shared.getEpisodes(limit: 20, libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}
