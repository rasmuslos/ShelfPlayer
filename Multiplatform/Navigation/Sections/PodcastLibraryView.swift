//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPBase

struct PodcastLibraryView: View {
    @Environment(\.libraryId) var libraryId
    
    @State var failed = false
    @State var podcasts = [Podcast]()
    
    var body: some View {
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
                        .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("title.library")
        .navigationBarTitleDisplayMode(.large)
        .modifier(NowPlayingBarSafeAreaModifier())
        .refreshable { await fetchItems() }
    }
}

extension PodcastLibraryView {
    func fetchItems() async {
        failed = false
        
        do {
            podcasts = try await AudiobookshelfClient.shared.getPodcasts(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}

#Preview {
    PodcastLibraryView()
}
