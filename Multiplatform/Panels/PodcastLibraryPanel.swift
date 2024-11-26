//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct PodcastLibraryPanel: View {
    @Default(.podcastsDisplayType) private var podcastsDisplayType
    
    @Environment(\.library) private var library
    
    @State private var search = ""
    @State private var lazyLoader = LazyLoadHelper<Podcast, String>.podcasts
    
    private var visible: [Podcast] {
        guard !search.isEmpty else {
            return lazyLoader.items
        }
        
        return lazyLoader.items.filter {
            $0.name.localizedCaseInsensitiveContains(search)
            || $0.authors.joined(separator: " ").localizedCaseInsensitiveContains(search)
        }
    }
    
    @ViewBuilder
    private var loadButton: some View {
        if visible.isEmpty && !lazyLoader.finished {
            Button {
                lazyLoader.didReachEndOfLoadedContent()
            } label: {
                Text("podcasts.loadMore")
                
                if lazyLoader.working {
                    ProgressIndicator()
                }
            }
            .disabled(lazyLoader.working)
            .padding(.top, 40)
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
                        .refreshable {
                            await lazyLoader.refresh()
                        }
                }
            } else {
                Group {
                    switch podcastsDisplayType {
                    case .grid:
                        ScrollView {
                            loadButton
                            
                            PodcastVGrid(podcasts: visible) {
                                if $0 == visible.last {
                                    lazyLoader.didReachEndOfLoadedContent()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    case .list:
                        List {
                            loadButton
                            
                            PodcastList(podcasts: visible) {
                                if $0 == visible.last {
                                    lazyLoader.didReachEndOfLoadedContent()
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .refreshable {
                    await lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.podcasts")
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(AccountSheetToolbarModifier(requiredSize: .compact))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        podcastsDisplayType = podcastsDisplayType == .list ? .grid : .list
                    }
                } label: {
                    Label(podcastsDisplayType == .list ? "display.list" : "display.grid", systemImage: podcastsDisplayType == .list ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        .onAppear {
            lazyLoader.library = library
        }
        .onReceive(Search.shared.searchPublisher) { (library, search) in
            self.search = search
        }
    }
}

#Preview {
    PodcastLibraryPanel()
        .environment(NowPlaying.ViewModel())
}
