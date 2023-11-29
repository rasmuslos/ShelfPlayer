//
//  EpisodeContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 22.11.23.
//

import SwiftUI
import AudiobooksKit

struct EpisodeContextMenuModifier: ViewModifier {
    let episode: Episode
    
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
                
                let progress = OfflineManager.shared.getProgress(item: episode)?.progress ?? 0
                Button {
                    Task {
                        await episode.setProgress(finished: progress < 1)
                    }
                } label: {
                    if progress >= 1 {
                        Label("progress.reset", systemImage: "xmark")
                    } else {
                        Label("progress.complete", systemImage: "checkmark")
                    }
                }
                
                // this crashed the app for reasons?
                /*
                Divider()
                
                if episode.offline == .none {
                    Button {
                        Task {
                            try! await OfflineManager.shared.downloadEpisode(episode)
                        }
                    } label: {
                        Label("download", systemImage: "arrow.down")
                    }
                } else {
                    Button {
                        try? OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                    } label: {
                        Label("download.remove", systemImage: "trash")
                    }
                }
                 */
            } preview: {
                VStack {
                    HStack {
                        ItemImage(image: episode.image)
                            .frame(height: 75)
                        
                        VStack(alignment: .leading) {
                            Group {
                                let durationText = Text(episode.duration.timeLeft(spaceConstrained: false, includeText: false))
                                
                                if let formattedReleaseDate = episode.formattedReleaseDate {
                                    Text(formattedReleaseDate)
                                    + Text(verbatim: " • ")
                                    + durationText
                                } else {
                                    durationText
                                }
                            }
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                            
                            Text(episode.name)
                                .font(.headline)
                            
                            Text(episode.podcastName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(episode.descriptionText ?? "description.unavailable")
                            .lineLimit(5)
                        
                        Spacer()
                    }
                    .padding(.top, 10)
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
