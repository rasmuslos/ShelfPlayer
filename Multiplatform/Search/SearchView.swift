//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct SearchView: View {
    @Environment(\.library) private var library
    
    @FocusState private var focused
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
                            AudiobookList(sections: viewModel.audiobooks.map { .audiobook(audiobook: $0) })
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("panel.search")
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.placeholder")
        .modify {
            if #available(iOS 18, *) {
                $0
                    .searchFocused($focused)
            } else {
                $0
            }
        }
        .autocorrectionDisabled()
        .modifier(NowPlaying.SafeAreaModifier())
        .environment(viewModel)
        .refreshable {
            viewModel.load()
        }
        .onAppear {
            viewModel.library = library
        }
        .onChange(of: viewModel.focusNotify) {
            focused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Self.focusNotification)) { _ in
            viewModel.focus(clear: true)
        }
        .onReceive(Search.shared.searchPublisher) { (library, search) in
            viewModel.focus(clear: true)
            viewModel.search = search
        }
        .modifier(AccountSheetToolbarModifier(requiredSize: .compact))
    }
    
    static let focusNotification = Notification.Name("io.rfk.shelfPlayer.search.focus")
}

@Observable
private final class SearchViewModel {
    @MainActor var library: Library!
    
    @MainActor var search: String {
        didSet {
            load()
        }
    }
    private var searchTask: Task<Void, Error>?
    
    @MainActor private(set) var loading: Bool
    
    @MainActor private(set) var series: [Series]
    @MainActor private(set) var authors: [Author]
    @MainActor private(set) var audiobooks: [Audiobook]
    
    @MainActor private(set) var errorNotify: Bool
    @MainActor private(set) var focusNotify: Bool
    
    @MainActor
    init() {
        search = ""
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
    func focus(clear: Bool) {
        focusNotify.toggle()
        
        if clear {
            search = ""
        }
    }
    
    func load() {
        searchTask?.cancel()
        searchTask = Task {
            let search = await self.search.trimmingCharacters(in: .whitespacesAndNewlines)
            
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
            
            var (audiobooks, _, authors, series) = try await AudiobookshelfClient.shared.items(search: search, libraryID: library.id)
            
            audiobooks.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
            authors.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
            series.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
            
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

#Preview {
    SearchView()
}
