//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct AudiobookAuthorsPanel: View {
    @Environment(\.library) private var library
    
    @Default(.authorsAscending) private var authorsAscending
    @Default(.authorsSortOrder) private var authorsSortOrder
    
    @State private var lazyLoader = LazyLoadHelper<Person, Void>.authors
    
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
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.authors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "arrow.up.arrow.down.circle") {
                    ItemSortOrderPicker(sortOrder: $authorsSortOrder, ascending: $authorsAscending)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: authorsSortOrder) {
            lazyLoader.sortOrder = authorsSortOrder
        }
        .onChange(of: authorsAscending) {
            lazyLoader.ascending = authorsAscending
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
    }
}

#Preview {
    #if DEBUG
    NavigationStack {
        AudiobookAuthorsPanel()
            .previewEnvironment()
    }
    #endif
}
