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
                        DownloadButton(item: viewModel.episode, downloadingLabel: false, progressIndicator: true)
                            .labelStyle(.iconOnly)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            QueuePlayButton(item: viewModel.episode)
                            QueueLaterButton(item: viewModel.episode)
                            
                            Divider()
                            
                            ItemLoadLink(itemID: viewModel.episode.podcastID)
                            
                            Divider()
                            
                            ProgressButton(item: viewModel.episode)
                            
                            if let progressEntity = viewModel.progressEntity, progressEntity.progress > 0 {
                                ProgressResetButton(item: viewModel.episode)
                            }
                            
                            /*
                             if viewModel.offlineTracker.status == .none {
                             ProgressButton(item: viewModel.audiobook)
                             DownloadButton(item: viewModel.audiobook)
                             } else {
                             if !viewModel.progressEntity.isFinished {
                             ProgressButton(item: viewModel.audiobook)
                             }
                             
                             Menu {
                             if viewModel.progressEntity.isFinished {
                             ProgressButton(item: viewModel.audiobook)
                             }
                             
                             if viewModel.progressEntity.startedAt != nil {
                             Button(role: .destructive) {
                             viewModel.resetProgress()
                             } label: {
                             Label("progress.reset", systemImage: "slash.circle")
                             }
                             }
                             
                             DownloadButton(item: viewModel.audiobook)
                             } label: {
                             Text("toolbar.remove")
                             }
                             }
                             */
                        } label: {
                            Label("more", systemImage: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}
