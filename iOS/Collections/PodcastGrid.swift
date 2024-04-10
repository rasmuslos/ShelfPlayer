//
//  PodcastList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase

struct PodcastVGrid: View {
    let podcasts: [Podcast]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible())].repeated(count: 2)) {
            ForEach(Array(podcasts.enumerated()), id: \.offset) { index, podcast in
                NavigationLink(destination: PodcastView(podcast: podcast)) {
                    PodcastGridItem(podcast: podcast)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                        .padding(.bottom, 5)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PodcastHGrid: View {
    let podcasts: [Podcast]
    
    var body: some View {
        let size = (UIScreen.main.bounds.width - 50) / 2
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(podcasts) { podcast in
                    NavigationLink(destination: PodcastLoadView(podcastId: podcast.id)) {
                        PodcastGridItem(podcast: podcast)
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

struct PodcastGridItem: View {
    let podcast: Podcast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemImage(image: podcast.image)
            
            Text(podcast.name)
                .lineLimit(1)
                .padding(.top, 7)
                .padding(.bottom, 3)
            
            if let author = podcast.author {
                Text(author)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            PodcastVGrid(podcasts: [
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
            ])
            .padding(.horizontal)
        }
    }
}
