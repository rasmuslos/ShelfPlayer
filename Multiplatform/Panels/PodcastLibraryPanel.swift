//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct PodcastLibraryPanel: View {
    @Environment(\.library) private var library
    
    @Default(.podcastsAscending) private var podcastsAscending
    @Default(.podcastsSortOrder) private var podcastsSortOrder
    @Default(.podcastsDisplayType) private var podcastsDisplayType
    
    @State private var lazyLoader = LazyLoadHelper<Podcast, String>.podcasts
    
    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                Group {
                    if lazyLoader.failed {
                        ErrorView()
                    } else if lazyLoader.working {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
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
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis") {
                    ItemDisplayTypePicker(displayType: $podcastsDisplayType)
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $podcastsSortOrder, ascending: $podcastsAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: podcastsAscending) {
            lazyLoader.ascending = podcastsAscending
        }
        .onChange(of: podcastsSortOrder) {
            lazyLoader.sortOrder = podcastsSortOrder
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
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
