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
        @Environment(AudiobookViewModel.self) private var viewModel
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        private var regularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        func body(content: Content) -> some View {
            content
                .navigationTitle(viewModel.audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(regularPresentation ? .automatic : viewModel.navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!viewModel.navigationBarVisible && !regularPresentation)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if viewModel.navigationBarVisible {
                            VStack {
                                Text(viewModel.audiobook.name)
                                    .font(.headline)
                                    .modifier(SerifModifier())
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
                    if !viewModel.navigationBarVisible && !regularPresentation {
                        ToolbarItem(placement: .navigation) {
                            FullscreenBackButton(navigationBarVisible: viewModel.navigationBarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        DownloadButton(item: viewModel.audiobook, downloadingLabel: false)
                            .labelStyle(.iconOnly)
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
                            
                            ForEach(viewModel.audiobook.series, id: \.name) { series in
                                NavigationLink(destination: SeriesLoadView(series: series)) {
                                    Label("series.view", systemImage: "text.justify.leading")
                                    Text(series.name)
                                }
                            }
                            
                            Divider()
                            
                            ProgressButton(item: viewModel.audiobook)
                            DownloadButton(item: viewModel.audiobook)
                        } label: {
                            Image(systemName: "ellipsis")
                                .modifier(FullscreenToolbarModifier(navigationBarVisible: viewModel.navigationBarVisible))
                        }
                    }
                }
        }
    }
}
