//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import UIImageColors
import AudiobooksKit

extension PodcastView {
    struct Header: View {
        let podcast: Podcast
        
        @Binding var navigationBarVisible: Bool
        @Binding var backgroundColor: UIColor
        
        var body: some View {
            ZStack {
                GeometryRectangle(treshold: -300, backgroundColor: Color(backgroundColor), navigationBarVisible: $navigationBarVisible)
                
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
            .background(Color(backgroundColor))
            .foregroundStyle(backgroundColor.isLight() ? .black : .white)
            .padding(.top, 100)
            .onAppear {
                Task.detached {
                    withAnimation {
                        if let cover = podcast.image, let data = try? Data(contentsOf: cover.url) {
                            let image = UIImage(data: data)
                            
                            if let colors = image?.getColors(quality: .low) {
                                backgroundColor = colors.background
                            }
                        }
                    }
                }
            }
        }
    }
}
