//
//  EpisodeLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let id: String
    let podcastId: String
    
    @State private var failed = false
    @State private var episode: Episode?
    
    var body: some View {
        if failed {
            EpisodeUnavailableView()
        } else if let episode = episode {
            EpisodeView(episode: episode)
        } else {
            LoadingView()
                .task { await fetchAudiobook() }
                .refreshable { await fetchAudiobook() }
        }
    }
    
    private func fetchAudiobook() async {
        failed = false
        
        if let episode = try? await AudiobookshelfClient.shared.item(itemId: podcastId, episodeId: id).0 as? Episode {
            self.episode = episode
        } else {
            failed = true
        }
    }
}
