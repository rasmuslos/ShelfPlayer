//
//  AudiobookAuthorsPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookAuthorsPanel: View {
    @Environment(\.library) private var library

    @State private var authorsAscending = AppSettings.shared.authorsAscending
    @State private var authorsSortOrder = AppSettings.shared.authorsSortOrder

    @State private var lazyLoader = LazyLoadHelper<Person, AuthorSortOrder>.authors

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
                    PersonList(people: lazyLoader.items, showImage: true) {
                        lazyLoader.performLoadIfRequired($0)
                    }

                    PanelItemCountLabel(total: lazyLoader.totalCount, type: .author, isLoading: lazyLoader.isLoading)
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.authors")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "arrow.up.arrow.down") {
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $authorsSortOrder, ascending: $authorsAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: authorsSortOrder) {
            AppSettings.shared.authorsSortOrder = authorsSortOrder
            lazyLoader.sortOrder = authorsSortOrder
        }
        .onChange(of: authorsAscending) {
            AppSettings.shared.authorsAscending = authorsAscending
            lazyLoader.ascending = authorsAscending
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
        AudiobookAuthorsPanel()
            .previewEnvironment()
    }
}
#endif
