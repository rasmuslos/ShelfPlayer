//
//  EpisodeView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

extension EpisodeView {
    struct Header: View {
        let episode: Episode
        var imageColors: Item.ImageColors
        
        @Binding var navigationBarVisible: Bool
        
        var body: some View {
            ZStack {
                FullscreenBackground(threshold: -300, backgroundColor: imageColors.background.opacity(0.9), navigationBarVisible: $navigationBarVisible)
                
                VStack(spacing: 5) {
                    ItemImage(image: episode.image)
                        .frame(width: 175)
                    
                    HStack(spacing: 0) {
                        if let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                            Text(verbatim: " • ")
                        }
                        
                        Text(episode.duration.timeLeft(spaceConstrained: false, includeText: false))
                    }
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                    .padding(.top, 7)
                    
                    VStack(spacing: 7) {
                        Text(episode.name)
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                            HStack {
                                Text(episode.podcastName)
                                Image(systemName: "chevron.right.circle")
                            }
                            .lineLimit(1)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 15)
                    
                    PlayButton(item: episode)
                }
                .padding(.top, 125)
                .padding(.horizontal, 20)
                .background {
                    LinearGradient(colors: [imageColors.background.opacity(0.9), .secondary.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                }
            }
        }
    }
}
