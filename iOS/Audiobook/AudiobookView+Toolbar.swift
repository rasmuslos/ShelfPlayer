//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        @Environment(AudiobookViewModel.self) var viewModel
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(viewModel.navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.navigationBarVisible)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.navigationBarVisible {
                            VStack {
                                Text(viewModel.audiobook.name)
                                    .font(.headline)
                                    .fontDesign(.serif)
                                    .lineLimit(1)
                                
                                if let author = viewModel.audiobook.author {
                                    Text(author)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                            .transition(.move(edge: .top))
                        } else {
                            Text(verbatim: "")
                        }
                    }
                }
                .toolbar {
                    if !viewModel.navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(navigationBarVisible: viewModel.navigationBarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                if viewModel.offlineTracker.status == .none {
                                    try! await OfflineManager.shared.download(audiobookId: viewModel.audiobook.id)
                                } else if viewModel.offlineTracker.status == .downloaded {
                                    OfflineManager.shared.delete(audiobookId: viewModel.audiobook.id)
                                }
                            }
                        } label: {
                            switch viewModel.offlineTracker.status {
                            case .none:
                                Image(systemName: "arrow.down")
                            case .working:
                                ProgressView()
                            case .downloaded:
                                Image(systemName: "xmark")
                            }
                        }
                        .contentTransition(.opacity)
                        .contentTransition(.symbolEffect)
                        .modifier(FullscreenToolbarModifier(navigationBarVisible: viewModel.navigationBarVisible))
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            if let authorId = viewModel.authorId {
                                NavigationLink(destination: AuthorLoadView(authorId: authorId)) {
                                    Label("author.view", systemImage: "person")
                                    
                                    if let author = viewModel.audiobook.author {
                                        Text(author)
                                    }
                                }
                            }
                            if let seriesId = viewModel.seriesId {
                                NavigationLink(destination: SeriesLoadView(seriesId: seriesId)) {
                                    Label("series.view", systemImage: "text.justify.leading")
                                    
                                    if let seriesName = viewModel.seriesName {
                                        Text(seriesName)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            ToolbarProgressButton(item: viewModel.audiobook)
                            
                            if viewModel.offlineTracker.status != .none {
                                Divider()
                                
                                Button(role: .destructive) {
                                    OfflineManager.shared.delete(audiobookId: viewModel.audiobook.id)
                                } label: {
                                    Label("download.remove", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .modifier(FullscreenToolbarModifier(navigationBarVisible: viewModel.navigationBarVisible))
                        }
                    }
                }
        }
    }
}
