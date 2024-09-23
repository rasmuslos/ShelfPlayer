//
//  EpisodeLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct EpisodeLoadView: View {
    let id: String
    let podcastId: String
    
    @State private var failed = false
    @State private var episode: Episode?
    
    var body: some View {
        if let episode {
            EpisodeView(episode)
        } else if failed {
            EpisodeUnavailableView()
                .refreshable {
                    await fetchAudiobook()
                }
        } else {
            LoadingView()
                .task {
                    await fetchAudiobook()
                }
                .refreshable {
                    await fetchAudiobook()
                }
        }
    }
    
    private nonisolated func fetchAudiobook() async {
        await MainActor.withAnimation {
            failed = false
        }
        
        guard let episode = try? await AudiobookshelfClient.shared.item(itemId: podcastId, episodeId: id).0 as? Episode else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.episode = episode
        }
    }
}
