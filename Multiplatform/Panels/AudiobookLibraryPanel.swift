//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct AudiobookLibraryPanel: View {
    @Environment(\.libraryId) private var libraryID
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.audiobooksFilter) private var filter
    @Default(.audiobooksDisplay) private var display
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @State private var selected = [String]()
    @State private var lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortFilter.SortOrder>.audiobooks
    
    private var genres: [String] {
        var genres = Set<String>()
        
        for audiobook in lazyLoader.items {
            for genre in audiobook.genres {
                genres.insert(genre)
            }
        }
        
        return Array(genres)
    }
    private var visible: [Audiobook] {
        let visible = AudiobookSortFilter.filterSort(audiobooks: lazyLoader.items, filter: filter, order: sortOrder, ascending: ascending)
        
        if selected.isEmpty {
            return visible
        }
        
        return visible.filter {
            let matches = $0.genres.reduce(0, { result, genre in
                selected.contains(where: { $0 == genre }) ? result + 1 : result
            })
            
            return matches == selected.count
        }
    }
    
    var body: some View {
        Group {
            if lazyLoader.count == 0 {
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            lazyLoader.initialLoad()
                        }
                } else {
                    LoadingView()
                        .task {
                            lazyLoader.initialLoad()
                        }
                }
            } else {
                Group {
                    switch display {
                        case .grid:
                            ScrollView {
                                AudiobookVGrid(audiobooks: visible)
                                    .padding(.horizontal, 20)
                            }
                        case .list:
                            List {
                                AudiobookList(audiobooks: visible) {
                                    if $0 == visible[max(0, visible.endIndex - 4)] {
                                        lazyLoader.didReachEndOfLoadedContent()
                                    }
                                }
                            }
                            .listStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        AudiobookSortFilter(displayType: $display, filter: $filter, sortOrder: $sortOrder, ascending: $ascending) {
                            lazyLoader.sortOrder = sortOrder
                            await lazyLoader.refresh()
                        }
                    }
                }
                .refreshable {
                    await lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("title.library")
        .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            lazyLoader.libraryID = libraryID
        }
    }
}

#Preview {
    NavigationStack {
        AudiobookLibraryPanel()
    }
}
