//
//  PodcastView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI


extension PodcastView {
    struct ToolbarModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(PodcastViewModel.self) private var viewModel
        
        private var isRegularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.podcast.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(isRegularPresentation ? .automatic : viewModel.isToolbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.isToolbarVisible && !isRegularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.isToolbarVisible {
                            VStack {
                                Text(viewModel.podcast.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("item.count.episodes \(viewModel.episodeCount)")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        OptionsMenu()
                    }
                }
                .toolbar {
                    if !viewModel.isToolbarVisible && !isRegularPresentation {
                        ToolbarItem(placement: .navigation) {
                            HeroBackButton()
                        }
                    }
                }
        }
    }
}

extension PodcastView.ToolbarModifier {
    struct OptionsMenu: View {
        @Environment(PodcastViewModel.self) private var viewModel
        
        var body: some View {
            Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease" : "line.3.horizontal") {
                Section("item.filter") {
                    ItemFilterPicker(filter: viewModel.filterBinding, restrictToPersisted: viewModel.restrictToPersistedBinding)
                }
                
                Section("item.sort") {
                    ItemSortOrderPicker(sortOrder: viewModel.sortOrderBinding, ascending: viewModel.ascendingBinding)
                }
                
                ItemConfigureButton(itemID: viewModel.podcast.id)
            }
            .menuActionDismissBehavior(.disabled)
        }
    }
}
