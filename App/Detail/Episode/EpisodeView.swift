//
//  EpisodeView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct EpisodeView: View {
    @Environment(Satellite.self) private var satellite

    @Environment(\.namespace) private var namespace
    @Environment(\.library) private var library

    let zoomID: UUID?

    @State private var viewModel: EpisodeViewModel

    init(_ episode: Episode, zoomID: UUID?) {
        self.zoomID = zoomID
        _viewModel = .init(initialValue: .init(episode: episode))
    }

    var body: some View {
        ScrollView {
            Header()

            EpisodeDescription(episode: viewModel.episode)
                .padding(.top, 20)
                .padding(.horizontal, 20)

            Footer()

            SubpageLink("timeline") {
                TimelinePage()
                    .environment(viewModel)
            }
            .padding(.top, 12)
        }
        .contentMargins(.top, 8, for: .scrollContent)
        .modify(if: zoomID) {
            $0
                .navigationTransition(.zoom(sourceID: $1, in: namespace!))
        }
        .id(viewModel.id)
        .hapticFeedback(.error, trigger: viewModel.notifyError)
        .modifier(ToolbarModifier())
        .modifier(PlaybackSafeAreaPaddingModifier())
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            viewModel.load(refresh: false)
        }
        .refreshable {
            viewModel.load(refresh: true)
        }
        .userActivity("io.rfk.shelfPlayer.item") { activity in
            activity.title = viewModel.episode.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = viewModel.episode.id.description

            Task {
                try await activity.webpageURL = viewModel.episode.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EpisodeView(.fixture, zoomID: .init())
    }
    .previewEnvironment()
}
#endif
