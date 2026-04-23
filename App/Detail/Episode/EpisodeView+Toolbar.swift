//
//  EpisodeView+Toolbar.swift
//  ShelfPlayer
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
                    ToolbarItem(placement: .principal) {
                        if viewModel.toolbarVisible {
                            Text(viewModel.episode.name)
                                .font(.headline)
                                .lineLimit(1)
                        } else {
                            Text(verbatim: "")
                        }
                    }

                    if !viewModel.toolbarVisible && !isRegularPresentation {
                        ToolbarItem(placement: .navigation) {
                            HeroBackButton()
                        }
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ProgressButton(itemID: viewModel.episode.id)
                            .labelStyle(.iconOnly)

                        Menu {
                            ControlGroup {
                                ItemShareButton(item: viewModel.episode)
                                ItemCollectionMembershipEditButton(itemID: viewModel.episode.id)
                            }

                            Divider()

                            QueuePlayButton(itemID: viewModel.episode.id)
                            QueueButton(itemID: viewModel.episode.id)
                            
                            DownloadButton(itemID: viewModel.episode.id, progressVisibility: .toolbar)

                            Divider()

                            ProgressButton(itemID: viewModel.episode.id)
                            ProgressResetButton(itemID: viewModel.episode.id)

                            Divider()

                            ItemLoadLink(itemID: viewModel.episode.podcastID, footer: viewModel.episode.podcastName)
                        } label: {
                            Label("item.options", systemImage: "ellipsis")
                        }
                    }
                }
        }
    }
}
