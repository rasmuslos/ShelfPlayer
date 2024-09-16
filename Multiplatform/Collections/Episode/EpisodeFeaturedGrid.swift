//
//  EpisodeFeaturedRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

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
        let amount = CGFloat(Int(usable / 250))
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
                HStack(spacing: 0) {
                    ForEach(episodes) { episode in
                        NavigationLink(destination: EpisodeView(episode)) {
                            EpisodeGridItem(episode: episode)
                                .frame(width: size)
                                .padding(.leading, gap)
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
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

private struct EpisodeGridItem: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let episode: Episode
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .aspectRatio(0.72, contentMode: .fill)
            
            Title(episode: episode)
        }
        .foregroundStyle(.white)
        .colorScheme(.light)
        .background(Background(cover: episode.cover))
        .clipShape(.rect(cornerRadius: 16))
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 16))
        .hoverEffect(.highlight)
        .modifier(EpisodeContextMenuModifier(episode: episode))
    }
}

private struct Title: View {
    let episode: Episode
    
    @State private var loading = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(episode.name)
                    .font(.headline)
                    .lineLimit(2)
                
                if let descriptionText = episode.descriptionText {
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.thickMaterial)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                HStack(spacing: 0) {
                    EpisodePlayButton(episode: episode, loading: $loading, highlighted: true)
                        .fixedSize()
                    
                    if let releaseDate = episode.releaseDate {
                        Text(releaseDate, format: .dateTime.day(.twoDigits).month(.twoDigits))
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                    
                    Spacer(minLength: 12)
                    
                    DownloadIndicator(item: episode)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

private struct Background: View {
    let cover: Cover?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ItemImage(cover: cover)
                    .frame(width: geometry.size.height)
                    .blur(radius: 15)
                
                ItemImage(cover: cover)
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
            EpisodeFeaturedGrid(episodes: .init(repeating: [.fixture], count: 7))
        }
    }
    .environment(NowPlaying.ViewModel())
}

#Preview {
    EpisodeGridItem(episode: .fixture)
        .environment(NowPlaying.ViewModel())
}
#endif
