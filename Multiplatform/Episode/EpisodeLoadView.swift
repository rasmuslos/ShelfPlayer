//
//  EpisodeLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct EpisodeLoadView: View {
    @Environment(NamespaceWrapper.self) private var namespaceWrapper
    
    let id: String
    let podcastId: String
    
    let zoom: Bool
    
    @State private var failed = false
    @State private var episode: Episode?
    
    var body: some View {
        Group {
            if let episode {
                EpisodeView(episode, zoom: zoom)
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
        .modify {
            if #available(iOS 18, *), zoom {
                $0
                    .navigationTransition(.zoom(sourceID: "episode_\(id)", in: namespaceWrapper.namepace))
            } else { $0 }
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
