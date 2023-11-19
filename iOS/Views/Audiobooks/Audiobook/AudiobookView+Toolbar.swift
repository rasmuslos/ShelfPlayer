//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import AudiobooksKit

extension AudiobookView {
    struct ToolbarModifier: ViewModifier {
        let audiobook: Audiobook
        
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
                            Text("")
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
                        HStack {
                            Button {
                                Task {
                                    if audiobook.offline == .none {
                                        try! await OfflineManager.shared.downloadAudiobook(audiobook)
                                    } else if audiobook.offline == .downloaded {
                                        try! OfflineManager.shared.deleteAudiobook(audiobookId: audiobook.id)
                                    }
                                }
                            } label: {
                                switch audiobook.offline {
                                case .none:
                                    Image(systemName: "arrow.down")
                                case .working:
                                    ProgressView()
                                case .downloaded:
                                    Image(systemName: "xmark")
                                }
                            }
                            .modifier(FullscreenToolbarModifier(navigationBarVisible: $navigationBarVisible))
                            
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
                                
                                if audiobook.offline != .none {
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        try! OfflineManager.shared.deleteAudiobook(audiobookId: audiobook.id)
                                    } label: {
                                        Label("downloads.delete.force", systemImage: "trash")
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
}
