//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct AudiobookSearchPanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @FocusState private var focused
    
    @State private var viewModel: SearchViewModel = .init()
    
    var body: some View {
        Group {
            if viewModel.isEmpty {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    UnavailableWrapper {
                        ContentUnavailableView("panel.search.empty", systemImage: "magnifyingglass", description: Text("panel.search.empty.description"))
                    }
                }
            } else {
                List {
                    if !viewModel.result.1.isEmpty {
                        Section("panel.search.authors") {
                            PersonList(people: viewModel.result.1, showImage: true) { _ in }
                        }
                    }
                    if !viewModel.result.2.isEmpty {
                        Section("panel.search.narrators") {
                            PersonList(people: viewModel.result.2, showImage: false) { _ in }
                        }
                    }
                    
                    if !viewModel.result.3.isEmpty {
                        Section("panel.search.series") {
                            SeriesList(series: viewModel.result.3) { _ in }
                        }
                    }
                    
                    if !viewModel.result.0.isEmpty {
                        Section("panel.search.audiobooks") {
                            AudiobookList(sections: viewModel.result.0.map { .audiobook(audiobook: $0) }) { _ in }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("panel.search")
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer(displayMode: .always), prompt: "panel.search.placeholder")
        .autocorrectionDisabled()
        .searchFocused($focused)
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .modifier(PlaybackSafeAreaPaddingModifier())
        .environment(viewModel)
        .refreshable {
            viewModel.load()
        }
        .modifier(CompactPreferencesToolbarModifier())
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
    }
}

@Observable @MainActor
private final class SearchViewModel: Sendable {
    var search: String
    
    var isLoading: Bool
    var result: ([Audiobook], [Person], [Person], [Series])
    
    private var searchTask: Task<Void, Never>?
    
    var library: Library?
    
    private(set) var notifyError: Bool
    private(set) var notifyFocus: Bool
    
    init() {
        search = ""
        isLoading = false
        
        result = ([], [], [], [])
        
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
                    self.result = ([], [], [], [])
                    self.isLoading = true
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.isLoading = true
            }
            
            do {
                var (audiobooks, authors, narrators, series) = try await ABSClient[library.connectionID].items(in: library, search: search)
                
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
                    self.result = (audiobooks, authors, narrators, series)
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

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookSearchPanel()
    }
    .previewEnvironment()
}
#endif
