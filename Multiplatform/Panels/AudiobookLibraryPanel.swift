//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct AudiobookLibraryPanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.audiobooksFilter) private var filter
    @Default(.audiobooksDisplayType) private var displayType
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @State private var genres: [String]? = nil
    @State private var isGenreFilterPresented = false
    
    @State private var lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    @State private var notifyError = false
    
    private func binding(for genre: String) -> Binding<Bool> {
        .init(get: { lazyLoader.filteredGenre == genre }, set: {
            if $0 {
                lazyLoader.filteredGenre = genre
            } else {
                lazyLoader.filteredGenre = nil
            }
        })
    }
    
    var body: some View {
        Group {
            if !lazyLoader.didLoad {
                Group {
                    if lazyLoader.failed {
                        ErrorView()
                    } else if lazyLoader.working {
                        LoadingView()
                            .task {
                                loadGenres()
                                lazyLoader.initialLoad()
                            }
                    } else {
                        EmptyCollectionView()
                    }
                }
                .refreshable {
                    loadGenres()
                    lazyLoader.refresh()
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
                .refreshable {
                    loadGenres()
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.library")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let genres, !genres.isEmpty {
                    Menu("item.genres", systemImage: "tag") {
                        ForEach(genres.sorted(by: <), id: \.hashValue) {
                            Toggle($0, isOn: binding(for: $0))
                        }
                    }
                    .labelStyle(.iconOnly)
                    .symbolVariant(lazyLoader.filteredGenre != nil ? .fill : .none)
                } else if genres == nil {
                    ProgressView()
                }
                
                Menu("item.options", systemImage: filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                    ItemDisplayTypePicker(displayType: $displayType)
                    
                    Divider()
                    
                    Section("item.filter") {
                        ItemFilterPicker(filter: $filter)
                    }
                    
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
                    }
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
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

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookLibraryPanel()
    }
    .previewEnvironment()
}
#endif
