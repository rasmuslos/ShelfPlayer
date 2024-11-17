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
    @Environment(\.library) private var library
    
    let episode: Episode
    
    private var isOffline: Bool {
        library.type == .offline
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
                
                NavigationLink(destination: EpisodeView(episode, zoom: false)) {
                    Label("episode.view", systemImage: "play.square.stack")
                }
                .disabled(isOffline)
                
                NavigationLink(destination: PodcastLoadView(podcastID: episode.podcastId, zoom: false)) {
                    Label("podcast.view", systemImage: "rectangle.stack")
                    Text(episode.podcastName)
                }
                .disabled(isOffline)
                
                Divider()
                
                ProgressButton(item: episode)
                DownloadButton(item: episode)
            } preview: {
                Preview(episode: episode)
            }
    }
}

internal extension EpisodeContextMenuModifier {
    struct Preview: View {
        let episode: Episode
        
        var body: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    ItemImage(cover: episode.cover)
                        .frame(width: 50, height: 50)
                    
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
                    .padding(.top, 8)
                    Text(episode.name)
                        .font(.headline)
                    
                    Text(episode.podcastName)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let descriptionText = episode.descriptionText {
                        Text(descriptionText)
                            .padding(.top, 4)
                            .frame(idealWidth: 400)
                    }
                }
                .padding(20)
                
                Spacer()
            }
        }
    }
}

#if DEBUG
#Preview {
    Text(":)")
        .modifier(EpisodeContextMenuModifier(episode: .fixture))
}
#endif
