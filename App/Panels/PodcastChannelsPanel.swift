//
//  PodcastChannelsPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.26.
//

import SwiftUI
import ShelfPlayback

/// Browses podcast channels — podcasts grouped by author.
///
/// Channels are a client-derived concept (Audiobookshelf has no podcast-author
/// entity), so the list is built by grouping the library's podcasts. It reuses
/// the same paginated podcast loader as the library tab — channels accumulate
/// as more podcasts page in — rather than fetching the whole library at once.
struct PodcastChannelsPanel: View {
    @Environment(\.library) private var library

    @State private var displayType = AppSettings.shared.podcastsDisplayType
    @State private var lazyLoader = LazyLoadHelper<Podcast, PodcastSortOrder>.podcasts

    private var channels: [Channel] {
        Channel.grouped(from: lazyLoader.items)
    }

    var body: some View {
        Group {
            if channels.isEmpty {
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
                switch displayType {
                case .grid:
                    ScrollView {
                        ChannelVGrid(channels: channels)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        loadMoreTrigger
                    }
                    .refreshable {
                        lazyLoader.refresh()
                    }
                case .list:
                    List {
                        ChannelList(channels: channels)

                        loadMoreTrigger
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        lazyLoader.refresh()
                    }
                }
            }
        }
        .navigationTitle("panel.channels")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $displayType)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: displayType) {
            AppSettings.shared.podcastsDisplayType = displayType
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
    }

    /// Keeps paging podcasts in (so far-down channels get their members) while
    /// more remain to load.
    @ViewBuilder
    private var loadMoreTrigger: some View {
        if !lazyLoader.finished {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 16)
            .onAppear {
                if let last = lazyLoader.items.last {
                    lazyLoader.performLoadIfRequired(last)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastChannelsPanel()
            .previewEnvironment()
    }
}
#endif
