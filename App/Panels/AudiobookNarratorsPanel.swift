//
//  AudiobookNarratorsPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 03.05.25.
//

import SwiftUI
import ShelfPlayback

struct AudiobookNarratorsPanel: View {
    @Environment(\.library) private var library

    @State private var narratorsAscending = AppSettings.shared.narratorsAscending
    @State private var narratorsSortOrder = AppSettings.shared.narratorsSortOrder

    @State private var lazyLoader = LazyLoadHelper<Person, NarratorSortOrder>.narrators

    private var isLoading: Bool { lazyLoader.working && !lazyLoader.failed }

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
                    PersonList(people: lazyLoader.items, showImage: false) {
                        lazyLoader.performLoadIfRequired($0)
                    }

                    PanelItemCountLabel(total: lazyLoader.totalCount, type: .narrator, isLoading: isLoading)
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.narrators")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "arrow.up.arrow.down") {
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $narratorsSortOrder, ascending: $narratorsAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: narratorsSortOrder) {
            AppSettings.shared.narratorsSortOrder = narratorsSortOrder
            lazyLoader.sortOrder = narratorsSortOrder
        }
        .onChange(of: narratorsAscending) {
            AppSettings.shared.narratorsAscending = narratorsAscending
            lazyLoader.ascending = narratorsAscending
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
        AudiobookNarratorsPanel()
            .previewEnvironment()
    }
}
#endif
