//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct SearchView: View {
    @Environment(\.libraryId) private var libraryId
    
    @State private var viewModel: SearchViewModel = .init()
    
    var body: some View {
        Group {
            if viewModel.isEmpty {
                if viewModel.loading {
                    LoadingView()
                } else {
                    UnavailableWrapper {
                        ContentUnavailableView("search.empty.title", systemImage: "magnifyingglass", description: Text("search.empty.description"))
                    }
                }
            } else {
                List {
                    if !viewModel.authors.isEmpty {
                        Section("section.authors") {
                            AuthorList(authors: viewModel.authors)
                        }
                    }
                    
                    if !viewModel.series.isEmpty {
                        Section("section.series") {
                            SeriesList(series: viewModel.series)
                        }
                    }
                    
                    if !viewModel.audiobooks.isEmpty {
                        Section("section.audiobooks") {
                            AudiobookList(audiobooks: viewModel.audiobooks)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("title.search")
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.placeholder")
        .modifier(SearchModifier())
        .modifier(NowPlaying.SafeAreaModifier())
        .environment(viewModel)
        .refreshable {
            viewModel.load()
        }
        .onAppear {
            viewModel.libraryId = libraryId
        }
        .modifier(AccountSheetToolbarModifier(requiredSize: .compact))
    }
}

@Observable
private class SearchViewModel {
    @MainActor var libraryId: String!
    
    @MainActor private var _search: String
    private var searchTask: Task<Void, Error>?
    
    @MainActor private(set) var loading: Bool
    
    @MainActor private(set) var series: [Series]
    @MainActor private(set) var authors: [Author]
    @MainActor private(set) var audiobooks: [Audiobook]
    
    @MainActor private(set) var errorNotify: Bool
    @MainActor private(set) var focusNotify: Bool
    
    @MainActor
    init() {
        _search = ""
        searchTask = nil
        
        loading = false
        
        series = []
        authors = []
        audiobooks = []
        
        errorNotify = false
        focusNotify = false
    }
}

private extension SearchViewModel {
    @MainActor
    var isEmpty: Bool {
        series.isEmpty && authors.isEmpty && audiobooks.isEmpty
    }
    
    @MainActor
    var search: String {
        get {
            _search
        }
        set {
            _search = newValue
            load()
        }
    }
    
    func load() {
        searchTask?.cancel()
        searchTask = Task {
            let search = await search.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if search.isEmpty {
                try Task.checkCancellation()
                
                await MainActor.withAnimation {
                    self.series = []
                    self.authors = []
                    self.audiobooks = []
                    
                    self.loading = false
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.loading = true
            }
            
            let (audiobooks, _, authors, series) = try await AudiobookshelfClient.shared.items(search: search, libraryId: libraryId)
            
            try Task.checkCancellation()
            
            await MainActor.withAnimation {
                self.series = series
                self.authors = authors
                self.audiobooks = audiobooks
                
                self.loading = false
            }
        }
    }
}

// TODO: Remove this

private struct SearchModifier: ViewModifier {
    @Environment(SearchViewModel.self) private var viewModel
    
    @FocusState private var focused: Bool
    
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 18, *) {
                content
                    .searchFocused($focused)
            } else {
                content
            }
        }
        .autocorrectionDisabled()
        .onChange(of: viewModel.focusNotify) {
            focused = true
        }
    }
}

#Preview {
    SearchView()
}
