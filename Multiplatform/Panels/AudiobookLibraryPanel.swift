//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import RFNetwork
import ShelfPlayerKit

internal struct AudiobookLibraryPanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.audiobooksFilter) private var filter
    @Default(.audiobooksDisplayType) private var displayType
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @State private var genres: [String]? = nil
    @State private var selected = [String]()
    @State private var genreFilterPresented = false
    
    @State private var lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    @State private var notifyError = false
    
    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            loadGenres()
                            lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .task {
                            loadGenres()
                            lazyLoader.initialLoad()
                        }
                        .refreshable {
                            loadGenres()
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
                        if let genres, !genres.isEmpty {
                            Button("genres", systemImage: "tag") {
                                genreFilterPresented.toggle()
                            }
                            .labelStyle(.iconOnly)
                        } else if genres == nil {
                            ProgressIndicator()
                        }
                        
                        Menu("options", systemImage: filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                            ItemDisplayTypePicker(displayType: $displayType)
                            
                            Divider()
                            
                            Section("filter") {
                                ItemFilterPicker(filter: $filter)
                            }
                            
                            Section("sort") {
                                AudiobookSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
                            }
                        }
                    }
                }
                .refreshable {
                    loadGenres()
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        // .modifier(NowPlaying.SafeAreaModifier())
        // .modifier(GenreFilterSheet(genres: genres, selected: $selected, isPresented: $genreFilterPresented))
        .sensoryFeedback(.error, trigger: notifyError)
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
    
    nonisolated private func loadGenres() {
        Task {
            guard let library = await library else {
                return
            }
            
            do {
                let genres = try await ABSClient[library.connectionID].genres(from: library.id)
                
                await MainActor.withAnimation {
                    self.genres = genres
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                    genres = []
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AudiobookLibraryPanel()
    }
}
