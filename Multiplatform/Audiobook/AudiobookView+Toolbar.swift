//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        @Environment(AudiobookViewModel.self) private var viewModel
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(regularPresentation ? .automatic : viewModel.toolbarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.toolbarVisible && !regularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.toolbarVisible {
                            VStack {
                                Text(viewModel.audiobook.name)
                                    .font(.headline)
                                    .modifier(SerifModifier())
                                    .lineLimit(1)
                                
                                if !viewModel.audiobook.authors.isEmpty {
                                    Text(viewModel.audiobook.authors, format: .list(type: .and, width: .short))
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
                    if !viewModel.toolbarVisible && !regularPresentation {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(isToolbarVisible: viewModel.toolbarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        DownloadButton(item: viewModel.audiobook, downloadingLabel: false, progressIndicator: true)
                            .labelStyle(.iconOnly)
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                viewModel.play()
                            } label: {
                                Label("queue.play", systemImage: "play.fill")
                            }
                            
                            QueueButton(item: viewModel.audiobook)
                            
                            Divider()
                            
                            AuthorMenu(authors: viewModel.audiobook.authors, libraryID: nil)
                            SeriesMenu(series: viewModel.audiobook.series, libraryID: nil)
                            
                            Divider()
                            
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
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
        }
    }
}
