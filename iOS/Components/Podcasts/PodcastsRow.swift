//
//  PodcastsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct PodcastsRow: View {
    let podcasts: [Podcast]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - 50) / 2
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(podcasts) { podcast in
                    NavigationLink(destination: PodcastLoadView(podcastId: podcast.id)) {
                        PodcastCover(podcast: podcast)
                            .frame(width: size)
                            .padding(.leading, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, 10)
            .padding(.trailing, 20)
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

struct PodcastsRowContainer: View {
    let title: String
    let podcasts: [Podcast]
    
    var body: some View {
        VStack(alignment: .leading) {
            RowTitle(title: title)
            PodcastsRow(podcasts: podcasts)
        }
    }
}

#Preview {
    NavigationStack {
        PodcastsRow(podcasts: [
            Podcast.fixture,
            Podcast.fixture,
            Podcast.fixture,
            Podcast.fixture,
            Podcast.fixture,
            Podcast.fixture,
        ])
    }
}
