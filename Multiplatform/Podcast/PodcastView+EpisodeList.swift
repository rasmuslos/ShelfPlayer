//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastEpisodesView: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        List {
            EpisodeSingleList(episodes: viewModel.visible)
        }
        .listStyle(.plain)
        .navigationTitle("episodes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.search, placement: .toolbar)
        // .modifier(NowPlaying.SafeAreaModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PodcastView.ToolbarModifier.OptionsMenu()
            }
        }
        .environment(viewModel)
        .onDisappear {
            viewModel.search = ""
        }
    }
}
