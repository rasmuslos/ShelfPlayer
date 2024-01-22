//
//  EpisodeFeatured.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

struct EpisodeFeatured: View {
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

// MARK: Background

extension EpisodeFeatured {
    struct Background: View {
        let image: Item.Image?
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    ItemImage(image: image)
                        .frame(width: geometry.size.height)
                        .blur(radius: 25)
                    
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

// MARK: Title

extension EpisodeFeatured {
    struct Title: View {
        let episode: Episode
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Text(formattedReleaseDate)
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
                        Spacer()
                        DownloadIndicator(item: episode)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
