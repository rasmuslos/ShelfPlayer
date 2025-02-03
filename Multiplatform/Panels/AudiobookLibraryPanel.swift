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
    @Default(.audiobooksDisplayType) private var displayType
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @Default(.collapseSeries) private var collapseSeries
    
    @State private var selected = [String]()
    @State private var genreFilterPresented = false
    @State private var lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    
    private var genres: [String] {
        var genres = Set<String>()
        
        for audiobook in lazyLoader.items {
            /*
             for genre in audiobook.genres {
             genres.insert(genre)
             }
             */
        }
        
        return Array(genres)
    }
    
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
                    switch displayType {
                    case .grid:
                        ScrollView {
                            AudiobookVGrid(sections: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }
                            .padding(.horizontal, 20)
                        }
                    case .list:
                        List {
                            AudiobookList(sections: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
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
                        
                        Menu("options", systemImage: filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                            ItemDisplayTypePicker(displayType: $displayType)
                            
                            Divider()
                            
                            Section("filter") {
                                ItemFilterPicker(filter: $filter)
                            }
                        }
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        // .modifier(NowPlaying.SafeAreaModifier())
        .modifier(GenreFilterSheet(genres: genres, selected: $selected, isPresented: $genreFilterPresented))
        .onChange(of: filter) {
            lazyLoader.filter = filter
        }
        .onChange(of: sortOrder) {
            lazyLoader.sortOrder = sortOrder
        }
        .onChange(of: ascending) {
            lazyLoader.ascending = ascending
        }
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
