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
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    
    @Default(.audiobooksFilter) private var filter
    @Default(.audiobooksRestrictToPersisted) private var restrictToPersisted
    @Default(.audiobooksDisplayType) private var displayType
    
    @Default(.audiobooksSortOrder) private var sortOrder
    @Default(.audiobooksAscending) private var ascending
    
    @State private var genres: [String]? = nil
    @State private var isGenreFilterPresented = false
    
    @State private var lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    @State private var notifyError = false
    
    private var libraryRowCount: CGFloat { 4 }
    @ViewBuilder
    private var libraryRows: some View {
        if let library {
            let rows = [
                TabValue.audiobookSeries(library),
                TabValue.audiobookAuthors(library),
                TabValue.audiobookNarrators(library),
                // collections
            ]
            
            ForEach(Array(rows.enumerated()), id: \.element) { (index, row) in
                NavigationLink(destination: row.content) {
                    Label(row.label, systemImage: row.image)
                        .foregroundStyle(.primary)
                }
                .listRowSeparator(index == 0 ? .hidden : .automatic, edges: .top)
            }
        }
    }
    
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
                            List {
                                libraryRows
                            }
                            .frame(height: defaultMinListRowHeight * libraryRowCount)
                            
                            AudiobookVGrid(sections: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
                            }
                            .padding(.horizontal, 20)
                        }
                    case .list:
                        List {
                            libraryRows
                            
                            AudiobookList(sections: lazyLoader.items) {
                                lazyLoader.performLoadIfRequired($0)
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
        .listStyle(.plain)
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
                        ItemFilterPicker(filter: $filter, restrictToPersisted: $restrictToPersisted)
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
        .onChange(of: restrictToPersisted) {
            lazyLoader.restrictToPersisted = restrictToPersisted
        }
        .onChange(of: sortOrder) {
            lazyLoader.sortOrder = sortOrder
        }
        .onChange(of: ascending) {
            lazyLoader.ascending = ascending
        }
        .task {
            loadGenres()
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
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
