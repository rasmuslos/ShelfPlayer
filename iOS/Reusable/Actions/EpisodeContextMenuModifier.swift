//
//  EpisodeContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.11.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

struct EpisodeContextMenuModifier: ViewModifier {
    let episode: Episode
    let offlineTracker: ItemOfflineTracker
    
    init(episode: Episode) {
        self.episode = episode
        offlineTracker = episode.offlineTracker
    }
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    Label("episode.view", systemImage: "waveform")
                }
                NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                    Label("podcast.view", systemImage: "tray.full")
                }
                
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
                    
                    Text(episode.name)
                        .font(.headline)
                    
                    Text(episode.podcastName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.bottom, 5)
                    
                    HStack {
                        Text(episode.descriptionText ?? "description.unavailable")
                            .lineLimit(5)
                        
                        Spacer()
                    }
                }
                .padding(20)
                .frame(width: 400)
            }
    }
}

#Preview {
    Text(":)")
        .modifier(EpisodeContextMenuModifier(episode: Episode.fixture))
}
