//
//  PodcastList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase

struct PodcastVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let podcasts: [Podcast]
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(podcasts) { podcast in
                NavigationLink(destination: PodcastView(podcast: podcast)) {
                    PodcastGridItem(podcast: podcast)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PodcastHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let podcasts: [Podcast]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 160 : 200.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(podcasts) { podcast in
                        NavigationLink(destination: PodcastLoadView(podcastId: podcast.id)) {
                            PodcastGridItem(podcast: podcast)
                                .frame(width: size)
                                .padding(.leading, gap)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

struct PodcastGridItem: View {
    let podcast: Podcast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ItemImage(image: podcast.image)
                .hoverEffect(.highlight)
            
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
        .contentShape(.hoverMenuInteraction, Rectangle())
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
            .padding(.horizontal, 20)
        }
    }
}
