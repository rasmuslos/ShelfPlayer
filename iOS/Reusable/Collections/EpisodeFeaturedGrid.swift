//
//  EpisodeFeaturedRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

struct EpisodeFeaturedGrid: View {
    let episodes: [Episode]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(episodes.enumerated()), id: \.offset) { index, episode in
                    NavigationLink(destination: EpisodeView(episode: episode)) {
                        EpisodeGridItem(episode: episode)
                            .padding(.trailing, index == episodes.count - 1 ? 20 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, 10)
            .padding(.trailing, 10)
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

extension EpisodeFeaturedGrid {
    struct EpisodeGridItem: View {
        let episode: Episode
        
        var body: some View {
            let width = (UIScreen.main.bounds.width - 50) / 1.5
            
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.5), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 325)
                
                Title(episode: episode)
            }
            .foregroundStyle(.white)
            .frame(width: width)
            .background(Background(image: episode.image))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .padding(.leading, 10)
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
                            .font(.subheadline.smallCaps())
                            .foregroundStyle(.regularMaterial)
                    }
                    
                    Text(episode.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(episode.descriptionText ?? "")
                        .font(.subheadline)
                        .lineLimit(3, reservesSpace: true)
                    
                    HStack {
                        EpisodePlayButton(episode: episode, highlighted: true)
                            .bold()
                        
                        Spacer()
                        DownloadIndicator(item: episode)
                    }
                }
                
                Spacer()
            }
            .padding()
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
