//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase
import SPExtension

struct EpisodeView: View {
    let episode: Episode
    
    @State var navigationBarVisible = false
    @State var imageColors = Item.ImageColors.placeholder
    
    var body: some View {
        ScrollView {
            Header(episode: episode, imageColors: imageColors, navigationBarVisible: $navigationBarVisible)
            
            Description(description: episode.description)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
        }
        .ignoresSafeArea(edges: .top)
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(ToolbarModifier(episode: episode, navigationBarVisible: navigationBarVisible, imageColors: imageColors))
        .onAppear {
            Task.detached {
                let colors = episode.getImageColors()
                
                Task { @MainActor in
                    withAnimation(.spring) {
                        self.imageColors = colors
                    }
                }
            }
        }
        .userActivity("io.rfk.shelfplayer.episode") {
            $0.title = episode.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = MediaResolver.shared.convertIdentifier(item: episode)
            $0.targetContentIdentifier = "episode:\(episode.id)::\(episode.podcastId)"
            $0.userInfo = [
                "episodeId": episode.id,
                "podcastId": episode.podcastId,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "item").appending(path: episode.podcastId)
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeView(episode: Episode.fixture)
    }
}
