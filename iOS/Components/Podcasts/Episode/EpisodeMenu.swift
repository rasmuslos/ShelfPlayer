//
//  EpisodeMenu.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeMenu: View {
    let episode: Episode
    
    var body: some View {
        Menu {
            NavigationLink(destination: EpisodeView(episode: episode)) {
                Label("episode.view", systemImage: "waveform")
            }
            NavigationLink(destination: PodcastLoadView(podcastId: episode.podcastId)) {
                Label("podcast.view", systemImage: "tray.full")
            }
            
            Divider()
            
            // it is truly beyond me why this crashed the app without any exceptions being thrown
            /*
            if episode.offline == .none {
                Button {
                    // Task {
                        // try! await OfflineManager.shared.downloadEpisode(episode)
                    // }
                } label: {
                    Label("Download", systemImage: "arrow.down")
                }
            } else {
                Button {
                    // try? OfflineManager.shared.deleteEpisode(episodeId: episode.id)
                } label: {
                    Label("Delete download", systemImage: "trash")
                }
            }
             */
            
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
        } label: {
            Image(systemName: "ellipsis")
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    EpisodeMenu(episode: Episode.fixture)
}
