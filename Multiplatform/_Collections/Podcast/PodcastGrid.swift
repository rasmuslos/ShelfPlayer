//
//  PodcastList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPFoundation

internal struct PodcastVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let podcasts: [Podcast]
    var onAppear: ((_ audiobook: Podcast) -> Void)? = nil
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 16)], spacing: 20) {
            ForEach(podcasts) { podcast in
                VStack(spacing: 0) {
                    if let onAppear {
                        PodcastGridItem(podcast: podcast)
                            .onAppear {
                                onAppear(podcast)
                            }
                    } else {
                        PodcastGridItem(podcast: podcast)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

internal struct PodcastHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let podcasts: [Podcast]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 12
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
                    ForEach(podcasts) {
                        PodcastGridItem(podcast: $0)
                            .frame(width: size)
                            .padding(.leading, gap)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, 20 - gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

private struct PodcastGridItem: View {
    @Environment(\.namespace) private var namespace
    
    let podcast: Podcast
    
    private var episodeCount: Int {
        podcast.incompleteEpisodeCount ?? podcast.episodeCount
    }
    
    var body: some View {
        NavigationLink(destination: ItemLoadView(podcast.id)) {
            VStack(alignment: .leading, spacing: 4) {
                ItemImage(item: podcast)
                    .hoverEffect(.highlight)
                
                if let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
                    Text("\(incompleteEpisodeCount) episodes.unplayed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(.hoverMenuInteraction, .rect)
            /*
            .overlay(alignment: .topTrailing) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.ultraThickMaterial)
                    .padding(4)
            }
             */
            .matchedTransitionSource(id: "item_\(podcast.id)", in: namespace!)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    @Previewable @Namespace var namespace
    
    NavigationStack {
        ScrollView {
            PodcastVGrid(podcasts: .init(repeating: .fixture, count: 7))
                .padding(.horizontal, 20)
        }
    }
    .environment(NamespaceWrapper(namespace))
}
    
#Preview {
    @Previewable @Namespace var namespace
    NavigationStack {
        PodcastHGrid(podcasts: .init(repeating: .fixture, count: 7))
    }
    .environment(NamespaceWrapper(namespace))
}
#endif
