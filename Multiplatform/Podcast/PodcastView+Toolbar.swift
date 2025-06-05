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
        @Environment(Satellite.self) private var satellite
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                ShareLink(item: viewModel.podcast, preview: SharePreview(viewModel.podcast.name, image: viewModel.podcast)) {
                    Label("action.share", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Section("item.filter") {
                    ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                }
                
                Section("item.sort") {
                    ItemSortOrderPicker(sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
                }
                
                Button("item.configure", systemImage: "gearshape") {
                    satellite.present(.configureGrouping(viewModel.podcast.id))
                }
            }
            .menuActionDismissBehavior(.disabled)
        }
    }
}
