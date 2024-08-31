//
//  EpisodeContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.11.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct EpisodeContextMenuModifier: ViewModifier {
    @Environment(\.libraryId) private var libraryId
    
    let episode: Episode
    
    private var isOffline: Bool {
        libraryId == "offline"
    }
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Task {
                        try await AudioPlayer.shared.play(episode)
                    }
                } label: {
                    Label("play", systemImage: "play")
                }
                
                QueueButton(item: episode)
                
                Divider()
                
                NavigationLink(destination: EpisodeView(episode)) {
                    Label("episode.view", systemImage: "waveform")
                }
                .disabled(isOffline)
                
                NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                    Label("podcast.view", systemImage: "tray.full")
                }
                .disabled(isOffline)
                
                Divider()
                
                ProgressButton(item: episode)
                DownloadButton(item: episode)
            } preview: {
                VStack(alignment: .leading, spacing: 8) {
                    ItemImage(image: episode.cover)
                        .frame(height: 50)
                    
                    Group {
                        let durationText = Text(episode.duration, format: .duration)
                        
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
                    .padding(.top, 4)
                    
                    Group {
                        Text(episode.name)
                            .font(.headline)
                        
                        Text(episode.podcastName)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(episode.descriptionText ?? "description.unavailable")
                    }
                    .multilineTextAlignment(.leading)
                }
                .frame(width: 300)
                .padding(20)
            }
    }
}

#if DEBUG
#Preview {
    Text(":)")
        .modifier(EpisodeContextMenuModifier(episode: .fixture))
}
#endif
