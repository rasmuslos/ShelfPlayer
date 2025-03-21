//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastLibraryPanel: View {
    @Environment(\.library) private var library
    @FocusState private var focused
    
    @Default(.podcastsAscending) private var podcastsAscending
    @Default(.podcastsSortOrder) private var podcastsSortOrder
    @Default(.podcastsDisplayType) private var podcastsDisplayType
    
    @State private var lazyLoader = LazyLoadHelper<Podcast, String>.podcasts
    
    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .task {
                            lazyLoader.initialLoad()
                        }
                        .refreshable {
                            lazyLoader.refresh()
                        }
                }
            } else {
                Group {
                    switch podcastsDisplayType {
                    case .grid:
                        ScrollView {
                            PodcastVGrid(podcasts: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }
                            .padding(.horizontal, 20)
                        }
                    case .list:
                        List {
                            PodcastList(podcasts: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        .searchable(text: $lazyLoader.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.podcasts")
        .searchFocused($focused)
        .modifier(CompactPreferencesToolbarModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("options", systemImage: "ellipsis.circle") {
                    ItemDisplayTypePicker(displayType: $podcastsDisplayType)
                    ItemSortOrderPicker(sortOrder: $podcastsSortOrder, ascending: $podcastsAscending)
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onAppear {
            lazyLoader.library = library
        }
        .onChange(of: podcastsAscending) {
            lazyLoader.ascending = podcastsAscending
        }
        .onChange(of: podcastsSortOrder) {
            lazyLoader.sortOrder = podcastsSortOrder
        }
        .onReceive(RFNotification[.focusSearchField].publisher()) {
            lazyLoader.search = ""
            focused = true
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastLibraryPanel()
    }
    .previewEnvironment()
}
#endif
