//
//  EpisodeView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeView: View {
    @Environment(NamespaceWrapper.self) private var namespaceWrapper
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
        .modify {
            if #available(iOS 18, *), let zoomID {
                $0.navigationTransition(.zoom(sourceID: zoomID, in: namespaceWrapper()))
            } else { $0 }
        }
        .sensoryFeedback(.error, trigger: viewModel.errorNotify)
        // .modifier(NowPlaying.SafeAreaModifier())
        .modifier(ToolbarModifier())
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            // await viewModel.load()
        }
        .refreshable {
            // await viewModel.load()
        }
        .userActivity("io.rfk.shelfplayer.episode") {
            $0.title = viewModel.episode.name
            $0.isEligibleForHandoff = true
            // $0.persistentIdentifier = convertIdentifier(item: viewModel.episode)
            // $0.targetContentIdentifier = convertIdentifier(item: viewModel.episode)
            $0.userInfo = [:
                // "libraryID": viewModel.episode.libraryID,
                // "episodeID": viewModel.episode.id,
                // "podcastID": viewModel.episode.podcastId,
            ]
            // $0.webpageURL = viewModel.episode.url
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @Namespace var namespace
    
    NavigationStack {
        EpisodeView(.fixture, zoomID: .init())
    }
    .environment(NamespaceWrapper(namespace))
}
#endif
