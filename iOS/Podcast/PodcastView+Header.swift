//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import UIImageColors
import SPBase

extension PodcastView {
    struct Header: View {
        let podcast: Podcast
        let imageColors: Item.ImageColors
        
        @Binding var navigationBarVisible: Bool
        
        var body: some View {
            ZStack {
                FullscreenBackground(threshold: -250, backgroundColor: imageColors.background, navigationBarVisible: $navigationBarVisible)
                
                VStack {
                    ItemImage(image: podcast.image)
                        .frame(width: 200)
                    
                    Text(podcast.name)
                        .font(.headline)
                        .padding(.top)
                    
                    if let author = podcast.author {
                        Text(author)
                            .font(.subheadline)
                    }
                    
                    HStack {
                        if let description = podcast.description {
                            Text(description)
                                .font(.callout)
                                .lineLimit(3)
                                .padding(.top)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        HStack(spacing: 3) {
                            Image(systemName: "number")
                            Text(String(podcast.episodeCount))
                        }
                        
                        if podcast.explicit {
                            Text(verbatim: "•")
                            Image(systemName: "e.square.fill")
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
                    .padding(.top, 5)
                }
                .padding(.vertical)
                .padding(.horizontal, 15)
            }
            .background(imageColors.background)
            .foregroundStyle(imageColors.isLight ? .black : .white)
            .padding(.top, 100)
        }
    }
}
