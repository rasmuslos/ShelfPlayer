//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayerKit

internal struct PodcastLibraryPanel: View {
    @Environment(\.libraryId) private var libraryID
    
    @State private var search = ""
    @State private var lazyLoader = LazyLoadHelper<Podcast, String>.podcasts
    
    private var visible: [Podcast] {
        guard !search.isEmpty else {
            return lazyLoader.items
        }
        
        return lazyLoader.items.filter {
            $0.name.localizedCaseInsensitiveContains(search)
            || $0.author?.localizedCaseInsensitiveContains(search) ?? false
        }
    }
    
    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            await lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .onAppear {
                            lazyLoader.initialLoad()
                        }
                }
            } else {
                ScrollView {
                    if visible.isEmpty && !lazyLoader.finished {
                        Button {
                            lazyLoader.didReachEndOfLoadedContent()
                        } label: {
                            Text("podcasts.loadMore")
                        }
                        .padding(.top, 40)
                    }
                    
                    PodcastVGrid(podcasts: visible) {
                        if $0 == visible.last {
                            lazyLoader.didReachEndOfLoadedContent()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("title.library")
        .searchable(text: $search, prompt: "search.podcasts")
        .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            lazyLoader.libraryID = libraryID
        }
    }
}

#Preview {
    PodcastLibraryPanel()
}
