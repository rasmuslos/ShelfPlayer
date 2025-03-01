//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct SearchView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    @FocusState private var focused
    
    @State private var isPrefrenceSheetPresented = false
    
    @State private var viewModel: SearchViewModel = .init()
    
    var body: some View {
        Group {
            if viewModel.isEmpty {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    UnavailableWrapper {
                        ContentUnavailableView("search.empty.title", systemImage: "magnifyingglass", description: Text("search.empty.description"))
                    }
                }
            } else {
                List {
                    if !viewModel.result.1.isEmpty {
                        Section("section.authors") {
                            AuthorList(authors: viewModel.result.1) { _ in }
                        }
                    }
                    
                    if !viewModel.result.2.isEmpty {
                        Section("section.series") {
                            SeriesList(series: viewModel.result.2) { _ in }
                        }
                    }
                    
                    if !viewModel.result.0.isEmpty {
                        Section("section.audiobooks") {
                            AudiobookList(sections: viewModel.result.0.map { .audiobook(audiobook: $0) }) { _ in }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("panel.search")
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "search.placeholder")
        .searchFocused($focused)
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .autocorrectionDisabled()
        // .modifier(NowPlaying.SafeAreaModifier())
        .environment(viewModel)
        .refreshable {
            viewModel.load()
        }
        .onAppear {
            viewModel.library = library
        }
        .onChange(of: viewModel.notifyFocus) {
            focused = true
        }
        .onChange(of: viewModel.search) {
            viewModel.load()
        }
        .onReceive(RFNotification[.focusSearchField].publisher()) {
            viewModel.focus(clear: true)
        }
        /*
        .onReceive(Search.shared.searchPublisher) { (library, search) in
            viewModel.focus(clear: true)
            viewModel.search = search
        }
         */
        .modify {
            if horizontalSizeClass == .compact {
                $0
                    .toolbar {
                        Button("prefrences") {
                            isPrefrenceSheetPresented.toggle()
                        }
                    }
                    .sheet(isPresented: $isPrefrenceSheetPresented) {
                        NavigationStack {
                            PrefrencesView()
                        }
                    }
            } else {
                $0
            }
        }
    }
}

@Observable @MainActor
private final class SearchViewModel: Sendable {
    var search: String
    
    var isLoading: Bool
    var result: ([Audiobook], [Author], [Series])
    
    private var searchTask: Task<Void, Never>?
    
    var library: Library?
    
    private(set) var notifyError: Bool
    private(set) var notifyFocus: Bool
    
    init() {
        search = ""
        isLoading = false
        
        result = ([], [], [])
        
        notifyError = false
        notifyFocus = false
    }
    
    var isEmpty: Bool {
        search.isEmpty || result.0.isEmpty && result.1.isEmpty && result.2.isEmpty
    }
    
    func focus(clear: Bool) {
        notifyFocus.toggle()
        
        if clear {
            search = ""
        }
    }
    
    func load() {
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
                    self.result = ([], [], [])
                    self.isLoading = true
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.isLoading = true
            }
            
            do {
                var (audiobooks, authors, series) = try await ABSClient[library.connectionID].items(in: library, search: search)
                
                if Task.isCancelled {
                    return
                }
                
                audiobooks.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                authors.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                series.sort { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                
                if Task.isCancelled {
                    return
                }
                
                await MainActor.withAnimation {
                    self.result = (audiobooks, authors, series)
                    self.isLoading = false
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
