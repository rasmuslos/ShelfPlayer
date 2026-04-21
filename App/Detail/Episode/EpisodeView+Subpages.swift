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
            ScrollView {
                Timeline(sessionLoader: viewModel.sessionLoader, item: viewModel.episode)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            .navigationTitle("timeline")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }
}
