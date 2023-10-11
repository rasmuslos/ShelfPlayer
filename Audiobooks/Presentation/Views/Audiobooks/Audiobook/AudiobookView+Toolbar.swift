//
//  AudiobookView+Toolbar.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

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
                                        Label("View author", systemImage: "person")
                                    }
                                }
                                if let seriesId = seriesId {
                                    NavigationLink(destination: SeriesLoadView(seriesId: seriesId)) {
                                        Label("View series", systemImage: "text.justify.leading")
                                    }
                                }
                                
                                Divider()
                                
                                let progress = OfflineManager.shared.getProgress(item: audiobook)?.progress ?? 0
                                Button {
                                    Task {
                                        await audiobook.setProgress(finished: progress < 1)
                                    }
                                } label: {
                                    if progress >= 1 {
                                        Label("Mark as unfinished", systemImage: "xmark")
                                    } else {
                                        Label("Mark as finished", systemImage: "checkmark")
                                    }
                                }
                                
                                if audiobook.offline != .none {
                                    Button(role: .destructive) {
                                        try! OfflineManager.shared.deleteAudiobook(audiobookId: audiobook.id)
                                    } label: {
                                        Label("Force delete", systemImage: "trash")
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
