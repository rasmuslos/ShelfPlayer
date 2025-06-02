//
//  AudiobookLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import DefaultsMacros
import ShelfPlayback

struct AudiobookLibraryPanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    
    @FocusState private var focused: Bool
    
    @State private var viewModel = LibraryViewModel()
    
    private var libraryRowCount: CGFloat {
        horizontalSizeClass == .compact && library != nil ? 4 :  0
    }
    @ViewBuilder
    private var libraryRows: some View {
        if horizontalSizeClass == .compact, let library {
            let rows = [
                TabValue.audiobookSeries(library),
                TabValue.audiobookAuthors(library),
                TabValue.audiobookNarrators(library),
                TabValue.audiobookBookmarks(library),
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
    @ViewBuilder
    private var libraryRowsList: some View {
        List {
            libraryRows
        }
        .frame(height: defaultMinListRowHeight * libraryRowCount)
    }
    
    @ViewBuilder
    private var listPresentation: some View {
        List {
            libraryRows
            
            AudiobookList(sections: viewModel.lazyLoader.items) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
        }
    }
    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            libraryRowsList
            
            AudiobookVGrid(sections: viewModel.lazyLoader.items) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
            .padding(.horizontal, 20)
        }
    }
    
    var body: some View {
        Group {
            if viewModel.showPlaceholders {
                ScrollView {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal, .vertical])
                        
                        VStack(spacing: 0) {
                            if viewModel.search.isEmpty {
                                libraryRowsList
                                    .frame(alignment: .top)
                            }
                            
                            Group {
                                if viewModel.isLoading {
                                    LoadingView.Inner()
                                } else if viewModel.lazyLoader.failed {
                                    ErrorViewInner()
                                } else {
                                    EmptyCollectionView.Inner()
                                }
                            }
                            .frame(alignment: .center)
                        }
                    }
                }
            } else {
                if let searchResult = viewModel.searchResult {
                    List {
                        if viewModel.searchScope.shouldShow(.authors) && !searchResult.1.isEmpty {
                            Section("panel.search.authors") {
                                PersonList(people: searchResult.1, showImage: true) { _ in }
                            }
                        }
                        if viewModel.searchScope.shouldShow(.narrators) && !searchResult.2.isEmpty {
                            Section("panel.search.narrators") {
                                PersonList(people: searchResult.2, showImage: false) { _ in }
                            }
                        }
                        
                        if viewModel.searchScope.shouldShow(.series) && !searchResult.3.isEmpty {
                            Section("panel.search.series") {
                                SeriesList(series: searchResult.3) { _ in }
                            }
                        }
                        
                        if viewModel.searchScope.shouldShow(.audiobooks) && !searchResult.0.isEmpty {
                            Section("panel.search.audiobooks") {
                                AudiobookList(sections: searchResult.0.map { .audiobook(audiobook: $0) }) { _ in }
                            }
                        }
                    }
                } else {
                    switch viewModel.displayType {
                        case .grid:
                            gridPresentation
                        case .list:
                            listPresentation
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("panel.library")
        .searchable(text: $viewModel.search, placement: .toolbar, prompt: "panel.search")
        .searchDictationBehavior(.inline(activation: .onLook))
        .searchScopes($viewModel.searchScope, activation: .onTextEntry) {
            ForEach(SearchScope.allCases) {
                Text($0.label)
                    .tag($0)
            }
        }
        .searchFocused($focused, equals: true)
        .toolbar {
            if viewModel.search.isEmpty {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let genres = viewModel.genres, !genres.isEmpty {
                        Menu("item.genres", systemImage: "tag") {
                            ForEach(genres.sorted(by: <), id: \.hashValue) {
                                Toggle($0, isOn: viewModel.binding(for: $0))
                            }
                        }
                        .labelStyle(.iconOnly)
                        .symbolVariant(viewModel.lazyLoader.filteredGenre != nil ? .fill : .none)
                    } else if viewModel.genres == nil {
                        ProgressView()
                    }
                    
                    Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
                        ItemDisplayTypePicker(displayType: $viewModel.displayType)
                        
                        Divider()
                        
                        Section("item.filter") {
                            ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                        }
                        
                        Section("item.sort") {
                            ItemSortOrderPicker(sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
                        }
                    }
                    .menuActionDismissBehavior(.disabled)
                }
            }
        }
        .modifier(CompactPreferencesToolbarModifier())
        .modifier(PlaybackSafeAreaPaddingModifier())
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .onChange(of: viewModel.filter) {
            viewModel.lazyLoader.filter = viewModel.filter
        }
        .onChange(of: viewModel.restrictToPersisted) {
            viewModel.lazyLoader.restrictToPersisted = viewModel.restrictToPersisted
        }
        .onChange(of: viewModel.sortOrder) {
            viewModel.lazyLoader.sortOrder = viewModel.sortOrder
        }
        .onChange(of: viewModel.ascending) {
            viewModel.lazyLoader.ascending = viewModel.ascending
        }
        .task {
            viewModel.load()
        }
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.library = library
            viewModel.lazyLoader.initialLoad()
        }
        .onReceive(RFNotification[.focusSearchField].publisher()) {
            viewModel.clear()
            focused.toggle()
        }
    }
}

// MARK: View Model

@MainActor @Observable
private final class LibraryViewModel {
    @ObservableDefault(.audiobooksFilter) @ObservationIgnored
    var filter: ItemFilter
    @ObservableDefault(.audiobooksRestrictToPersisted) @ObservationIgnored
    var restrictToPersisted: Bool
    @ObservableDefault(.audiobooksDisplayType) @ObservationIgnored
    var displayType: ItemDisplayType
    
    @ObservableDefault(.audiobooksSortOrder) @ObservationIgnored
    var sortOrder: AudiobookSortOrder
    @ObservableDefault(.audiobooksAscending) @ObservationIgnored
    var ascending: Bool
    
    var search = "" {
        didSet {
            searchDidChange()
        }
    }
    
    var searchScope = SearchScope.all
    var searchResult: ([Audiobook], [Person], [Person], [Series])? = nil
    
    private(set) var genres: [String]? = nil
    var isGenreFilterPresented = false
    
    let lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks
    
    private var searchTask: Task<Void, Never>?
    var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }
    
    private(set) var notifyError = false
    
    // MARK: Helper
    
    var showPlaceholders: Bool {
        if !search.isEmpty {
            guard let searchResult else {
                return true
            }
            
            var hasProblem = true
            
            if searchScope.shouldShow(.authors) && !searchResult.1.isEmpty {
                hasProblem = false
            } else if searchScope.shouldShow(.narrators) && !searchResult.2.isEmpty {
                hasProblem = false
            } else if searchScope.shouldShow(.series) && !searchResult.3.isEmpty {
                hasProblem = false
            } else if searchScope.shouldShow(.audiobooks) && !searchResult.0.isEmpty {
                hasProblem = false
            }
            
            return hasProblem
        }
        
        return !lazyLoader.didLoad
    }
    var isLoading: Bool {
        (lazyLoader.working && !lazyLoader.failed) || (!search.isEmpty && searchResult == nil)
    }
    
    nonisolated func load() {
        loadGenres()
    }
    nonisolated func refresh() {
        lazyLoader.refresh()
        loadGenres()
    }
    
    func clear() {
        search = ""
    }
}

// MARK: Search

private extension LibraryViewModel {
    func searchDidChange() {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            if search != "" {
                search = ""
            }
            
            searchResult = nil
            searchTask?.cancel()
            
            return
        }
        
        searchTask?.cancel()
        searchTask = Task.detached {
            guard let library = await self.library else {
                return
            }
            
            do {
                try await Task.sleep(for: .seconds(0.5))
                try Task.checkCancellation()
            } catch {
                return
            }
            
            let search = await self.search.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !search.isEmpty else {
                if Task.isCancelled {
                    return
                }
                
                await MainActor.withAnimation {
                    self.searchResult = nil
                }
                
                return
            }
            
            do {
                var (audiobooks, authors, narrators, series, _) = try await ABSClient[library.connectionID].items(in: library, search: search)
                
                if Task.isCancelled {
                    return
                }
                
                audiobooks.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                authors.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                narrators.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                series.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                
                if Task.isCancelled {
                    return
                }
                
                await MainActor.withAnimation {
                    self.searchResult = (audiobooks, authors, narrators, series)
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                }
            }
        }
    }
}

// MARK: Genres

extension LibraryViewModel {
    func binding(for genre: String) -> Binding<Bool> {
        .init { self.lazyLoader.filteredGenre == genre } set: {
            if $0 {
                self.lazyLoader.filteredGenre = genre
            } else {
                self.lazyLoader.filteredGenre = nil
            }
        }
    }
    
    private nonisolated func loadGenres() {
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
                await MainActor.withAnimation {
                    notifyError.toggle()
                    genres = []
                }
            }
        }
    }
}

// MARK: Scopes

private enum SearchScope: Int, Hashable, Identifiable, CaseIterable {
    case all
    case series
    case authors
    case narrators
    case audiobooks
    
    var id: Int {
        rawValue
    }
    var label: LocalizedStringKey {
        switch self {
            case .all:
                "filter.all"
            case .series:
                "item.series"
            case .authors:
                "item.authors"
            case .narrators:
                "item.narrators"
            case .audiobooks:
                "item.audiobooks"
        }
    }
    
    func shouldShow(_ other: SearchScope) -> Bool {
        if self == other {
            return true
        } else {
            return self == .all
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
