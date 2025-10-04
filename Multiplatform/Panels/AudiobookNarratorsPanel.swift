//
//  AudiobookNarratorsPanel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.05.25.
//

import SwiftUI
import ShelfPlayback

struct AudiobookNarratorsPanel: View {
    @Environment(\.library) private var library
    
    @Default(.narratorsAscending) private var narratorsAscending
    @Default(.narratorsSortOrder) private var narratorsSortOrder
    
    @State private var lazyLoader = LazyLoadHelper<Person, NarratorSortOrder>.narrators
    
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
                Menu("item.options", systemImage: "arrow.up.arrow.down.circle") {
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $narratorsSortOrder, ascending: $narratorsAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: narratorsSortOrder) {
            lazyLoader.sortOrder = narratorsSortOrder
        }
        .onChange(of: narratorsAscending) {
            lazyLoader.ascending = narratorsAscending
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
        AudiobookNarratorsPanel()
            .previewEnvironment()
    }
    #endif
}
