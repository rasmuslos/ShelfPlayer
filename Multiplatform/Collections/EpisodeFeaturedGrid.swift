//
//  EpisodeFeaturedRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct EpisodeFeaturedGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let episodes: [Episode]
    
    @State private var width: CGFloat? = nil
    
    private let gap: CGFloat = 12
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        guard let width else {
            return 250
        }
        
        if horizontalSizeClass == .compact {
            return (width - (gap + padding * 2)) / 1.5
        }
        
        let usable = width - padding * 2
        let paddedSize = 250 + gap
        
        let amount = CGFloat(Int(usable / paddedSize))
        let available = usable - gap * (amount - 1)
        
        return max(250, available / amount)
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
                HStack(spacing: gap) {
                    ForEach(episodes) {
                        EpisodeGridItem(episode: $0, gap: gap, size: size)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

private struct EpisodeGridItem: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.namespace) private var namespace
    
    let episode: Episode
    
    let gap: CGFloat
    let size: CGFloat
    
    @State private var zoomID = UUID()
    
    var body: some View {
        NavigationLink(value: NavigationDestination.item(episode, zoomID)) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .aspectRatio(0.72, contentMode: .fill)
                
                Title(episode: episode)
            }
            .foregroundStyle(.white)
            .colorScheme(.light)
            .background(Background(episode: episode))
            .clipShape(.rect(cornerRadius: 16))
            .universalContentShape(.rect(cornerRadius: 16))
            .matchedTransitionSource(id: zoomID, in: namespace!)
        }
        .buttonStyle(.plain)
        .modifier(ItemStatusModifier(item: episode))
        .frame(width: size)
        .secondaryShadow(radius: 8, opacity: 0.4)
    }
}

private struct Title: View {
    let episode: Episode
    @State private var download: DownloadStatusTracker
    
    init(episode: Episode) {
        self.episode = episode
        _download = .init(initialValue: .init(itemID: episode.id))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                if let releaseDate = episode.releaseDate {
                    Text(releaseDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.regularMaterial)
                }
                
                Text(episode.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let descriptionText = episode.descriptionText {
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.thickMaterial)
                        .lineLimit(2)
                }
                
                EpisodeItemActions(episode: episode, context: .featured)
                    .padding(.top, 6)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

private struct Background: View {
    let episode: Episode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ItemImage(item: episode, size: .tiny, contrastConfiguration: nil)
                    .frame(width: geometry.size.height)
                    .blur(radius: 15)
                
                ItemImage(item: episode, size: .regular, contrastConfiguration: nil)
                    .frame(height: geometry.size.width)
                    .mask {
                        LinearGradient(colors: [.black, .black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                    }
            }
        }
    }
    
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            EpisodeFeaturedGrid(episodes: .init(repeating: .fixture, count: 7))
        }
    }
    .previewEnvironment()
}
#endif
