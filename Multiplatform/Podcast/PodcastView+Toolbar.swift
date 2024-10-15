//
//  PodcastView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

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
                .toolbarBackground(isRegularPresentation ? .automatic : viewModel.toolbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.toolbarVisible && !isRegularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.toolbarVisible {
                            VStack {
                                Text(viewModel.podcast.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("\(viewModel.episodeCount) episodes")
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        @Bindable var viewModel = viewModel
                        
                        Menu {
                            PodcastSettingsSheet.DownloadSettings(maxEpisodes: $viewModel.fetchConfiguration.maxEpisodes, autoDownloadEnabled: $viewModel.fetchConfiguration.autoDownload)
                            PodcastSettingsSheet.NotificationToggle(autoDownloadEnabled: viewModel.fetchConfiguration.autoDownload, notificationsEnabled: $viewModel.fetchConfiguration.notifications)
                            
                            Divider()
                            
                            ControlGroup {
                                Button {
                                    viewModel.fetchConfiguration.maxEpisodes -= 1
                                } label: {
                                    Image(systemName: "minus")
                                }
                                
                                Text(String(viewModel.fetchConfiguration.maxEpisodes))
                                
                                Button {
                                    viewModel.fetchConfiguration.maxEpisodes -= 1
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.down.to.line.circle")
                                .labelStyle(.iconOnly)
                        } primaryAction: {
                            viewModel.settingsSheetPresented.toggle()
                        }
                        .menuActionDismissBehavior(.disabled)
                        .onChange(of: viewModel.fetchConfiguration) {
                            try? viewModel.fetchConfiguration.modelContext?.save()
                        }
                    }
                }
                .toolbar {
                    if !viewModel.toolbarVisible && !isRegularPresentation {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(isLight: viewModel.dominantColor?.isLight(), isToolbarVisible: viewModel.toolbarVisible)
                        }
                    }
                }
        }
    }
}
