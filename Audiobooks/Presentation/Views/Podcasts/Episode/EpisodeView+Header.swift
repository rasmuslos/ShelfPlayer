//
//  EpisodeView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

extension EpisodeView {
    struct Header: View {
        let episode: Episode
        
        @Binding var navigationBarVisible: Bool
        @Binding var backgroundColor: UIColor
        
        var body: some View {
            ZStack {
                GeometryRectangle(treshold: -320, backgroundColor: Color(backgroundColor).opacity(0.9), navigationBarVisible: $navigationBarVisible)
                
                VStack {
                    ItemImage(image: episode.image)
                        .frame(width: 150)
                    
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Group {
                            Text(formattedReleaseDate)
                            + Text(verbatim: " • ")
                            + Text(episode.duration.timeLeft(spaceConstrained: false, includeText: false))
                        }
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 5)
                    }
                    
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
                    
                    PlayButton(item: episode)
                    .padding()
                    .padding(.bottom, 10)
                }
                .padding(.top, 100)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background {
                    LinearGradient(colors: [Color(backgroundColor).opacity(0.9), .secondary.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                }
                .onAppear {
                    Task.detached {
                        withAnimation {
                            if let cover = episode.image, let data = try? Data(contentsOf: cover.url) {
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
}
