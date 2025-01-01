//
//  EpisodeLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct PodcastLoadView: View {
    @Environment(NamespaceWrapper.self) private var namespaceWrapper
    @Environment(\.library) private var library
    
    let podcastID: String
    let zoom: Bool
    
    @State private var failed = false
    @State private var podcast: (Podcast, [Episode])?
    
    var body: some View {
        Group {
            if let podcast = podcast {
                PodcastView(podcast.0, episodes: podcast.1, zoom: zoom)
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
                    .refreshable {
                        await fetchPodcast()
                    }
            }
        }
        .modify {
            if #available(iOS 18, *), zoom {
                $0
                    .navigationTransition(.zoom(sourceID: "podcast_\(podcastID)", in: namespaceWrapper.namepace))
            } else { $0 }
        }
    }
    
    private nonisolated func fetchPodcast() async {
        /*
        guard let podcast = try? await AudiobookshelfClient.shared.podcast(podcastId: podcastID) else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.podcast = podcast
        }
         */
    }
}
