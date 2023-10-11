//
//  PodcastLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI

extension PodcastLibraryView {
    struct LibraryView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var podcasts = [Podcast]()
        
        var body: some View {
            NavigationStack {
                Group {
                    if failed {
                        ErrorView()
                    } else if podcasts.isEmpty {
                        LoadingView()
                    } else {
                            ScrollView {
                                PodcastsGrid(podcasts: podcasts)
                                    .padding(.horizontal)
                            }
                    }
                }
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                .modifier(NowPlayingBarSafeAreaModifier())
                .task(fetchPodcasts)
                .refreshable(action: fetchPodcasts)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Library", systemImage: "tray.full")
            }
        }
    }
}

extension PodcastLibraryView.LibraryView {
    @Sendable
    func fetchPodcasts() {
        Task.detached {
            if let podcasts = try? await AudiobookshelfClient.shared.getAllPodcasts(libraryId: libraryId) {
                self.podcasts = podcasts
            } else {
                failed = true
            }
        }
    }
}
