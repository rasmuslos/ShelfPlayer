//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeView: View {
    let episode: Episode
    
    @State var navigationBarVisible = false
    @State var backgroundColor: UIColor = .secondarySystemBackground
    
    var body: some View {
        ScrollView {
            Header(episode: episode, navigationBarVisible: $navigationBarVisible, backgroundColor: $backgroundColor)
            Description(description: episode.descriptionText)
            .padding()
        }
        .ignoresSafeArea(edges: .top)
        .modifier(ToolbarModifier(episode: episode, navigationBarVisible: $navigationBarVisible, backgroundColor: $backgroundColor))
        .modifier(NowPlayingBarSafeAreaModifier())
    }
}

#Preview {
    NavigationStack {
        EpisodeView(episode: Episode.fixture)
    }
}
