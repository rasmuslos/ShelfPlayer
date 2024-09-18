//
//  EpisodeLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct PodcastLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let podcastId: String
    
    @State private var failed = false
    @State private var podcast: (Podcast, [Episode])?
    
    var body: some View {
        if let podcast = podcast {
            PodcastView(podcast.0, episodes: podcast.1)
        } else if failed {
            PodcastUnavailableView()
                .refreshable {
                    await fetchPodcast()
                }
        } else {
            LoadingView()
                .task {
                    await fetchPodcast()
                }
        }
    }
    
    private nonisolated func fetchPodcast() async {
        guard let podcast = try? await AudiobookshelfClient.shared.podcast(podcastId: podcastId) else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.podcast = podcast
        }
    }
}
