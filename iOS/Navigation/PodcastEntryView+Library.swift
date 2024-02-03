//
//  PodcastLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

extension PodcastEntryView {
    struct LibraryView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var podcasts = [Podcast]()
        
        var body: some View {
            NavigationStack {
                Group {
                    if podcasts.isEmpty {
                        if failed {
                            ErrorView()
                        } else {
                            LoadingView()
                                .task { await fetchItems() }
                        }
                    } else {
                        ScrollView {
                            PodcastVGrid(podcasts: podcasts)
                                .padding(.horizontal)
                        }
                    }
                }
                .navigationTitle("title.library")
                .navigationBarTitleDisplayMode(.large)
                .modifier(NowPlayingBarSafeAreaModifier())
                .refreshable { await fetchItems() }
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.library", systemImage: "tray.full")
            }
        }
    }
}

extension PodcastEntryView.LibraryView {
    func fetchItems() async {
        failed = false
        
        do {
            podcasts = try await AudiobookshelfClient.shared.getPodcasts(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}
