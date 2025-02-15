//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPFoundation
import SPPersistence

extension EpisodeView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(EpisodeViewModel.self) private var viewModel
        
        private var isRegularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.episode.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(isRegularPresentation ? .automatic : viewModel.toolbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.toolbarVisible && !isRegularPresentation)
                .toolbar {
                    if !viewModel.toolbarVisible {
                        ToolbarItem(placement: .principal) {
                            Text(verbatim: "")
                        }
                        
                        if !isRegularPresentation {
                            ToolbarItem(placement: .navigation) {
                                FullscreenBackButton(isLight: viewModel.dominantColor?.isLight, isToolbarVisible: false)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        DownloadButton(item: viewModel.episode, showProgress: true)
                            .labelStyle(.iconOnly)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            QueuePlayButton(item: viewModel.episode)
                            QueueLaterButton(item: viewModel.episode)
                            
                            Divider()
                            
                            ItemLoadLink(itemID: viewModel.episode.podcastID, footer: viewModel.episode.podcastName)
                            
                            Divider()
                            
                            DownloadButton(item: viewModel.episode)
                            ProgressButton(item: viewModel.episode)
                            ProgressResetButton(item: viewModel.episode)
                        } label: {
                            Label("more", systemImage: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}
