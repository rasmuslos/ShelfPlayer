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
        
        @State var backgroundColor: UIColor = .secondarySystemBackground
        
        var body: some View {
            ZStack {
                GeometryReader { reader in
                    let offset = reader.frame(in: .global).minY
                    
                    if offset > 0 {
                        Rectangle()
                            .foregroundStyle(Color(backgroundColor).opacity(0.9))
                            .offset(y: -offset)
                            .frame(height: offset)
                    }
                }
                
                VStack {
                    ItemImage(image: episode.image)
                        .frame(width: 150)
                    
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Group {
                            Text(formattedReleaseDate)
                            + Text(" • ")
                            + Text(episode.duration.timeLeft(spaceConstrained: false, includeText: true))
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
                    
                    Button {
                        
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 100)
                            .padding(.vertical, 12)
                            .background(.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
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
