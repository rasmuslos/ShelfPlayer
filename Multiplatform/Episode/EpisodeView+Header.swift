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
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        let episode: Episode
        var imageColors: Item.ImageColors
        
        @Binding var navigationBarVisible: Bool
        
        var body: some View {
            ZStack {
                FullscreenBackground(threshold: horizontalSizeClass == .regular ? -100 : -300, backgroundColor: imageColors.background.opacity(0.9), navigationBarVisible: $navigationBarVisible)
                
                ViewThatFits {
                    RegularPresentation(episode: episode)
                    CompactPresentation(episode: episode)
                }
                .background {
                    LinearGradient(colors: [imageColors.background.opacity(0.9), .secondary.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                }
            }
        }
    }
}

extension EpisodeView.Header {
    struct Eyebrow: View {
        let episode: Episode
        
        var body: some View {
            HStack(spacing: 0) {
                if let releaseDate = episode.releaseDate {
                    Text(releaseDate, style: .date)
                    Text(verbatim: " • ")
                }
                
                Text(episode.duration.timeLeft(spaceConstrained: false, includeText: false))
            }
            .font(.caption.smallCaps())
            .foregroundStyle(.secondary)
        }
    }
    
    struct Title: View {
        let episode: Episode
        let alignment: HorizontalAlignment
        
        var body: some View {
            VStack(alignment: alignment, spacing: 7) {
                Text(episode.name)
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)
                
                HStack {
                    NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                        Text(episode.podcastName)
                        Image(systemName: "chevron.right.circle")
                    }
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
        }
    }
}

extension EpisodeView.Header {
    struct CompactPresentation: View {
        let episode: Episode
        
        var body: some View {
            VStack(spacing: 5) {
                ItemImage(image: episode.image)
                    .frame(width: 175)
                
                Eyebrow(episode: episode)
                    .padding(.top, 7)
                Title(episode: episode, alignment: .center)
                    .padding(.vertical, 15)
                
                PlayButton(item: episode)
            }
            .padding(.top, 125)
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
    }
    
    struct RegularPresentation: View {
        let episode: Episode
        
        var body: some View {
            HStack(spacing: 20) {
                ItemImage(image: episode.image)
                    .frame(width: 225)
                
                VStack(alignment: .leading) {
                    Spacer()
                    
                    Eyebrow(episode: episode)
                    Title(episode: episode, alignment: .leading)
                    
                    Spacer()
                    
                    PlayButton(item: episode)
                }
            }
            .padding(20)
            .padding(.top, 75)
        }
    }
}
