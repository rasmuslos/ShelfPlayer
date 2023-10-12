//
//  PodcastList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI

struct PodcastsGrid: View {
    let podcasts: [Podcast]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible())].repeated(count: 2)) {
            ForEach(Array(podcasts.enumerated()), id: \.offset) { index, podcast in
                NavigationLink(destination: PodcastView(podcast: podcast)) {
                    PodcastCover(podcast: podcast)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                        .padding(.bottom, 5)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            PodcastsGrid(podcasts: [
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
            ])
        }
    }
}
