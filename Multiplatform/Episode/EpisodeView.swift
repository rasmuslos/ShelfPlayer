//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeView: View {
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
            
            Description(description: viewModel.episode.description)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            
            DisclosureGroup("timeline", isExpanded: $viewModel.sessionsVisible) {
                Timeline(item: viewModel.episode, sessions: viewModel.sessions)
                    .padding(.top, 8)
            }
            .disclosureGroupStyle(BetterDisclosureGroupStyle(horizontalLabelPadding: 20))
        }
        .ignoresSafeArea(edges: .top)
        .navigationTransition(.zoom(sourceID: zoomID, in: namespace!))
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        // .modifier(NowPlaying.SafeAreaModifier())
        .modifier(ToolbarModifier())
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            viewModel.load()
        }
        .refreshable {
            viewModel.load()
        }
        .userActivity("io.rfk.shelfPlayer.item") { activity in
            activity.title = viewModel.episode.name
            activity.isEligibleForHandoff = true
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
