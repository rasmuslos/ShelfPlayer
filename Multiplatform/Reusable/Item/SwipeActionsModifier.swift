//
//  SwipeActionsModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct SwipeActionsModifier: ViewModifier {
    let item: PlayableItem
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                DownloadButton(item: item, tint: true)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                ProgressButton(item: item, tint: true)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    Task {
                        try await AudioPlayer.shared.play(item)
                    }
                } label: {
                    Label("play", systemImage: "play")
                }
                .tint(.accentColor)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if let episode = item as? Episode {
                    NavigationLink {
                        PodcastLoadView(podcastId: episode.podcastId)
                    } label: {
                        Label("podcast.view", systemImage: "tray.full")
                    }
                }
            }
    }
}
