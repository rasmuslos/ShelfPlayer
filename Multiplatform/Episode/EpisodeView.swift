//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeView: View {
    let episode: Episode
    
    @State var navigationBarVisible = false
    @State var imageColors = ImageColors()
    
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
        .userActivity("io.rfk.shelfplayer.episode") {
            $0.title = episode.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = convertIdentifier(item: episode)
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
