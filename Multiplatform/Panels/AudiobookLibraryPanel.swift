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
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.audiobooksFilter) private var filter
    @Default(.audiobooksDisplay) private var display
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @State private var selected = [String]()
    @State private var genreFilterPresented = false
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
                            await lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .task {
                            lazyLoader.initialLoad()
                        }
                        .refreshable {
                            await lazyLoader.refresh()
                        }
                }
            } else {
                Group {
                    switch display {
                        case .grid:
                            ScrollView {
                                AudiobookVGrid(audiobooks: visible) {
                                    if $0 == visible.last {
                                        lazyLoader.didReachEndOfLoadedContent()
                                    }
                                }
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
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            genreFilterPresented.toggle()
                        } label: {
                            Label("genres", systemImage: "tag")
                                .labelStyle(.iconOnly)
                        }
                        
                        AudiobookSortFilter(displayType: $display, filter: $filter, sortOrder: $sortOrder, ascending: $ascending) {
                            lazyLoader.sortOrder = sortOrder
                            lazyLoader.ascending = ascending
                            
                            await lazyLoader.refresh()
                        }
                    }
                }
                .refreshable {
                    await lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(GenreFilterSheet(genres: genres, selected: $selected, isPresented: $genreFilterPresented))
        .onAppear {
            lazyLoader.library = library
        }
    }
}

#Preview {
    NavigationStack {
        AudiobookLibraryPanel()
    }
}
