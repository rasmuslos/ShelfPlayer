//
//  EpisodeView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import ShelfPlayback

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
                                HeroBackButton()
                            }
                        }
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        DownloadButton(itemID: viewModel.episode.id, progressVisibility: .toolbar)
                            .labelStyle(.iconOnly)
                        
                        Menu {
                            ItemShareButton(item: viewModel.episode)
                            
                            Divider()
                            
                            QueuePlayButton(itemID: viewModel.episode.id)
                            QueueButton(itemID: viewModel.episode.id)
                            
                            Divider()
                            
                            DownloadButton(itemID: viewModel.episode.id)
                            ItemCollectionMembershipEditButton(itemID: viewModel.episode.id)
                            
                            Divider()
                            
                            ItemLoadLink(itemID: viewModel.episode.podcastID, footer: viewModel.episode.podcastName)
                            
                            Divider()
                            
                            ProgressButton(itemID: viewModel.episode.id)
                            ProgressResetButton(itemID: viewModel.episode.id)
                        } label: {
                            Label("item.options", systemImage: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}
