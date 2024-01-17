//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineKit
import SPOfflineExtendedKit

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        let audiobook: Audiobook
        let offlineTracker: ItemOfflineTracker
        
        init(audiobook: Audiobook, navigationBarVisible: Binding<Bool>, authorId: Binding<String?>, seriesId: Binding<String?>) {
            self.audiobook = audiobook
            
            offlineTracker = audiobook.offlineTracker
            
            _navigationBarVisible = navigationBarVisible
            _authorId = authorId
            _seriesId = seriesId
        }
        
        @Binding var navigationBarVisible: Bool
        @Binding var authorId: String?
        @Binding var seriesId: String?
        
        func body(content: Content) -> some View {
            content
                .toolbarBackground(navigationBarVisible ? .visible : .hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(!navigationBarVisible)
                .navigationTitle(audiobook.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if navigationBarVisible {
                            VStack {
                                Text(audiobook.name)
                                    .font(.headline)
                                    .fontDesign(.serif)
                                    .lineLimit(1)
                                
                                if let author = audiobook.author {
                                    Text(author)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                        } else {
                            Text(verbatim: "")
                        }
                    }
                }
                .toolbar {
                    if !navigationBarVisible {
                        ToolbarItem(placement: .navigation) {
                            CustomBackButton(navigationBarVisible: $navigationBarVisible)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                if offlineTracker.status == .none {
                                    try! await OfflineManager.shared.download(audiobookId: audiobook.id)
                                } else if offlineTracker.status == .downloaded {
                                    OfflineManager.shared.delete(audiobookId: audiobook.id)
                                }
                            }
                        } label: {
                            switch offlineTracker.status {
                            case .none:
                                Image(systemName: "arrow.down")
                            case .working:
                                ProgressView()
                            case .downloaded:
                                Image(systemName: "xmark")
                            }
                        }
                        .modifier(FullscreenToolbarModifier(navigationBarVisible: $navigationBarVisible))
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            if let authorId = authorId {
                                NavigationLink(destination: AuthorLoadView(authorId: authorId)) {
                                    Label("author.view", systemImage: "person")
                                }
                            }
                            if let seriesId = seriesId {
                                NavigationLink(destination: SeriesLoadView(seriesId: seriesId)) {
                                    Label("series.view", systemImage: "text.justify.leading")
                                }
                            }
                            
                            Divider()
                            
                            ToolbarProgressButton(item: audiobook)
                            
                            if offlineTracker.status != .none {
                                Divider()
                                
                                Button(role: .destructive) {
                                    OfflineManager.shared.delete(audiobookId: audiobook.id)
                                } label: {
                                    Label("download.remove", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .modifier(FullscreenToolbarModifier(navigationBarVisible: $navigationBarVisible))
                        }
                    }
                }
        }
    }
}
