//
//  EpisodeView+Subpages.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.04.26.
//

import SwiftUI
import ShelfPlayback

extension EpisodeView {
    struct TimelinePage: View {
        @Environment(EpisodeViewModel.self) private var viewModel

        var body: some View {
            Timeline(sessionLoader: viewModel.sessionLoader, item: viewModel.episode)
                .navigationTitle("timeline")
                .navigationBarTitleDisplayMode(.inline)
                .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }
}
