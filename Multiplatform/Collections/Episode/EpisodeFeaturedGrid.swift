//
//  EpisodeFeaturedRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

struct EpisodeFeaturedGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let episodes: [Episode]
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
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
                        NavigationLink(destination: EpisodeView(episode: episode)) {
                            EpisodeGridItem(episode: episode)
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
        }
    }
}

extension EpisodeFeaturedGrid {
    struct EpisodeGridItem: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let episode: Episode
        
        var body: some View {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .aspectRatio(0.8, contentMode: .fill)
                
                Title(episode: episode)
            }
            .foregroundStyle(.white)
            .background(Background(image: episode.image))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .modifier(EpisodeContextMenuModifier(episode: episode))
        }
    }
}

extension EpisodeFeaturedGrid.EpisodeGridItem {
    struct Title: View {
        let episode: Episode
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    if let releaseDate = episode.releaseDate {
                        Text(releaseDate, style: .date)
                            .font(.caption.smallCaps())
                            .fontWeight(.bold)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Text(episode.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let descriptionText = episode.descriptionText {
                        Text(descriptionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    
                    HStack {
                        EpisodePlayButton(episode: episode, highlighted: true)
                            .bold()
                        
                        Spacer()
                        
                        DownloadIndicator(item: episode)
                    }
                }
                
                Spacer()
            }
            .padding(15)
        }
    }
    
    struct Background: View {
        let image: Item.Image?
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    ItemImage(image: image)
                        .frame(width: geometry.size.height)
                        .blur(radius: 15)
                    
                    ItemImage(image: image)
                        .frame(height: geometry.size.width)
                        .mask {
                            LinearGradient(colors: [.black, .black, .black.opacity(0)], startPoint: .top, endPoint: .bottom)
                        }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView(.horizontal) {
            EpisodeFeaturedGrid(episodes: [
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
            ])
        }
    }
}

#Preview {
    EpisodeFeaturedGrid.EpisodeGridItem(episode: .fixture)
}
