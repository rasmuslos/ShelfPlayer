//
//  EpisodeLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

struct PodcastLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let podcastId: String
    
    @State private var failed = false
    @State private var podcast: Podcast?
    
    var body: some View {
        if failed {
            PodcastUnavailableView()
        } else if let podcast = podcast {
            PodcastView(podcast: podcast)
        } else {
            LoadingView()
                .task { await fetchPodcast() }
                .refreshable { await fetchPodcast() }
        }
    }
    
    private func fetchPodcast() async {
        failed = false
        
        if let (podcast, _) = try? await AudiobookshelfClient.shared.getPodcast(podcastId: podcastId) {
            self.podcast = podcast
        } else {
            failed = true
        }
    }
}
