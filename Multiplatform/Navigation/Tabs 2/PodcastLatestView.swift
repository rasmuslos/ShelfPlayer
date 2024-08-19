//
//  PodcastLatestView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPFoundation

struct PodcastLatestView: View {
    @Environment(\.libraryId) var libraryId
    
    @State var failed = false
    @State var episodes = [Episode]()
    
    var body: some View {
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
                .modifier(NowPlaying.SafeAreaModifier())
            }
        }
        .navigationTitle("title.latest")
        .task{ await fetchItems() }
        .refreshable{ await fetchItems() }
    }
}

extension PodcastLatestView {
    func fetchItems() async {
        failed = false
        
        do {
            episodes = try await AudiobookshelfClient.shared.getEpisodes(limit: 20, libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}

#Preview {
    PodcastLatestView()
}
