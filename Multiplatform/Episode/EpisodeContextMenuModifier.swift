//
//  EpisodeContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.11.23.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPOfflineExtended

struct EpisodeContextMenuModifier: ViewModifier {
    @Environment(\.libraryId) private var libraryId
    
    let episode: Episode
    
    private var offline: Bool {
        libraryId == "offline"
    }
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    episode.startPlayback()
                } label: {
                    Label("play", systemImage: "play")
                }
                
                Divider()
                
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    Label("episode.view", systemImage: "waveform")
                }
                .disabled(offline)
                NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                    Label("podcast.view", systemImage: "tray.full")
                }
                .disabled(offline)
                
                Divider()
                
                ProgressButton(item: episode)
                DownloadButton(item: episode)
            } preview: {
                VStack(alignment: .leading) {
                    ItemImage(image: episode.image)
                        .frame(height: 50)
                    
                    Group {
                        let durationText = Text(episode.duration.timeLeft(spaceConstrained: false, includeText: false))
                        
                        if let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                            + Text(verbatim: " • ")
                            + durationText
                        } else {
                            durationText
                        }
                    }
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
                    
                    Group {
                        Text(episode.name)
                            .font(.headline)
                        
                        Text(episode.podcastName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.bottom, 5)
                        
                        Text(episode.descriptionText ?? "description.unavailable")
                    }
                    .multilineTextAlignment(.leading)
                }
                .frame(width: 300)
                .padding(20)
            }
    }
}

#Preview {
    Text(":)")
        .modifier(EpisodeContextMenuModifier(episode: Episode.fixture))
}
