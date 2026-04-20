//
//  FilteredAudiobooksView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayback

struct FilteredAudiobooksView: View {
    @Environment(\.library) private var library

    let title: String
    let filterKey: FilterKey
    let filterValue: String

    @State private var lazyLoader = LazyLoadHelper<AudiobookSection, AudiobookSortOrder>.audiobooks

    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
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
                List {
                    AudiobookList(sections: lazyLoader.items) {
                        lazyLoader.performLoadIfRequired($0)
                    }

                    PanelItemCountLabel(total: lazyLoader.totalCount, type: .none, isLoading: lazyLoader.isLoading)
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle(title)
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onAppear {
            lazyLoader.library = library

            switch filterKey {
            case .genre:
                lazyLoader.filteredGenre = filterValue
            case .tag:
                lazyLoader.filteredTag = filterValue
            }

            lazyLoader.initialLoad()
        }
    }

    enum FilterKey: Hashable {
        case genre
        case tag
    }
}
