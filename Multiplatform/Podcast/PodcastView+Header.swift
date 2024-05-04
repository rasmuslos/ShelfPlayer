//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

extension PodcastView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let podcast: Podcast
        let imageColors: Item.ImageColors
        
        @Binding var navigationBarVisible: Bool
        
        var body: some View {
            ZStack {
                FullscreenBackground(threshold: horizontalSizeClass == .regular ? -150 : -280, backgroundColor: imageColors.background, navigationBarVisible: $navigationBarVisible)
                
                // Because both of these have approximately the same size `ViewThatFits` does not work here.
                if horizontalSizeClass == .compact {
                    CompactPresentation(podcast: podcast)
                } else {
                    RegularPresentation(podcast: podcast)
                }
            }
            .background(imageColors.background)
            .foregroundStyle(imageColors.isLight ? .black : .white)
        }
    }
}

extension PodcastView.Header {
    struct Title: View {
        let podcast: Podcast
        
        let largeFont: Bool
        let alignment: TextAlignment
        
        var body: some View {
            Text(podcast.name)
                .font(largeFont ? .title : .headline)
                .lineLimit(4)
                .multilineTextAlignment(alignment)
            
            if let author = podcast.author {
                Text(author)
                    .font(largeFont ? .title2 : .subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(alignment)
            }
        }
    }
    struct Description: View {
        let podcast: Podcast
        
        var body: some View {
            HStack {
                if let description = podcast.description {
                    Text(description)
                        .font(.callout)
                        .lineLimit(3)
                }
                
                Spacer()
            }
        }
    }
    
    struct Additional: View {
        let podcast: Podcast
        
        var body: some View {
            HStack {
                HStack(spacing: 3) {
                    Label("episodes.count", systemImage: "number")
                        .labelStyle(.iconOnly)
                    Text(String(podcast.episodeCount))
                }
                
                if podcast.explicit {
                    Text(verbatim: "•")
                    Label("explicit", systemImage: "e.square.fill")
                        .labelStyle(.iconOnly)
                }
                
                if let type = podcast.type {
                    Text(verbatim: "•")
                    
                    switch type {
                        case .episodic:
                            Text("podcast.episodic")
                        case .serial:
                            Text("podcast.serial")
                    }
                }
                
                if podcast.genres.count > 0 {
                    Text(verbatim: "•")
                    Text(podcast.genres.joined(separator: ", "))
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .font(.footnote)
        }
    }
}

extension PodcastView.Header {
    struct CompactPresentation: View {
        let podcast: Podcast
        
        var body: some View {
            VStack {
                ItemImage(image: podcast.image)
                    .frame(width: 200)
                
                VStack(spacing: 10) {
                    Title(podcast: podcast, largeFont: false, alignment: .center)
                }
                .padding(.top, 20)
                
                Description(podcast: podcast)
                    .padding(.top, 20)
                Additional(podcast: podcast)
                    .padding(.top, 5)
            }
            .padding(20)
            .padding(.top, 100)
        }
    }
    
    struct RegularPresentation: View {
        let podcast: Podcast
        
        var body: some View {
            HStack(spacing: 40) {
                ItemImage(image: podcast.image)
                    .frame(height: 300)
                    .hoverEffect(.highlight)
                
                VStack(alignment: .leading, spacing: 10) {
                    Additional(podcast: podcast)
                        .foregroundStyle(.secondary)
                    Title(podcast: podcast, largeFont: true, alignment: .leading)
                    Description(podcast: podcast)
                }
                
                Spacer()
            }
            .padding(20)
            .padding(.top, 60)
        }
    }
}
