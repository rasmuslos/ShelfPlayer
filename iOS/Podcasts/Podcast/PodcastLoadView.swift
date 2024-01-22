//
//  EpisodeLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

struct PodcastLoadView: View {
    @Environment(\.libraryId) var libraryId
    
    let podcastId: String
    
    @State var failed = false
    @State var podcast: Podcast?
    
    var body: some View {
        if failed {
            PodcastUnavailableView()
        } else if let podcast = podcast {
            PodcastView(podcast: podcast)
        } else {
            LoadingView()
                .navigationBarBackButtonHidden()
                .task {
                    if let (podcast, _) = try? await AudiobookshelfClient.shared.getPodcast(podcastId: podcastId) {
                        self.podcast = podcast
                    } else {
                        failed = true
                    }
                }
        }
    }
}

#Preview {
    PodcastLoadView(podcastId: "fixture")
}
