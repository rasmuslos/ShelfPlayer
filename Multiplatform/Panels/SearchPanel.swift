//
//  SearchPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 06.10.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

struct SearchPanel: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @Environment(SearchViewModel.self) private var viewModel
    
    var body: some View {
        Group {
            if let result = viewModel.result {
                List {
                    ForEach(result) { item in
                        Group {
                            if library?.id == item.id.libraryID && library?.connectionID == item.id.connectionID {
                                NavigationLink(destination: ItemView(item: item)) {
                                    ItemCompactRow(item: item)
                                }
                            } else {
                                Button {
                                    item.id.navigate()
                                } label: {
                                    ItemCompactRow(item: item)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
                    }
                }
                .listStyle(.plain)
            } else if viewModel.isLoading {
                LoadingView()
            } else {
                ContentUnavailableView("panel.search", systemImage: "magnifyingglass")
            }
        }
        .navigationTitle("panel.search")
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: library, initial: true) {
            viewModel.library = library
        }
        .onReceive(RFNotification[.setGlobalSearch].publisher()) { search, scope in
            viewModel.scope = scope
            
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                viewModel.search = search
            }
        }
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
    }
}

struct SearchPanelModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(Satellite.self) private var satellite
    
    @State private var viewModel = SearchViewModel()
    
    func body(content: Content) -> some View {
        content
            .searchable(text: $viewModel.search, placement: .navigationBarDrawer)
            .searchScopes($viewModel.scope, activation: horizontalSizeClass == .compact ? .onSearchPresentation : .onTextEntry) {
                if let tabValue = satellite.tabValue {
                    Text(verbatim: "\"\(tabValue.library.name)\"")
                        .tag(SearchViewModel.SearchScope.library)
                }
                
                Text("panel.search.global")
                    .tag(SearchViewModel.SearchScope.global)
            }
            .environment(viewModel)
    }
}

@MainActor @Observable
final class SearchViewModel {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "SearchPanel")
    
    var search = "" {
        didSet {
            performSearch()
        }
    }
    var scope: SearchScope = .library {
        didSet {
            performSearch()
        }
    }
    
    var library: Library! {
        didSet {
            search = ""
            performSearch()
        }
    }
    
    var result: [Item]?
    var debounceTask: Task<Void, Never>?
    
    var notifyError = false
    
    var isLoading: Bool {
        debounceTask != nil
    }
    
    func performSearch() {
        debounceTask?.cancel()
        debounceTask = .detached {
            do {
                try await Task.sleep(for: .seconds(0.4))
                try Task.checkCancellation()
            } catch {
                self.logger.error("Failed to sleep: \(error)")
                return
            }
            
            let search = await self.search.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !search.isEmpty else {
                await MainActor.withAnimation {
                    self.result = nil
                    self.debounceTask = nil
                }
                
                return
            }
            
            let scope = await self.scope
            let result: [Item]
            
            do {
                switch scope {
                    case .library:
                        guard let library = await self.library else {
                            throw APIClientError.notFound
                        }
                        
                        let grouped = try await ABSClient[library.connectionID].items(in: library, search: search)
                        let part = grouped.4 + grouped.5
                        let presort = grouped.0 + grouped.1 + grouped.2 + grouped.3 + part
                        
                        result = presort.sorted { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                    case .global:
                        result = try await ShelfPlayerKit.globalSearch(query: search, includeOnlineSearchResults: true)
                }
            } catch {
                self.logger.error("Failed to search: \(error)")
                
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                    self.debounceTask = nil
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.debounceTask = nil
                self.result = result
            }
        }
    }
    
    enum SearchScope: Int, Identifiable, Hashable, CaseIterable {
        case library
        case global
        
        var id: Int {
            rawValue
        }
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(role: .search) {
            NavigationStack {
                SearchPanel()
            }
        }
    }
    .modifier(SearchPanelModifier())
    .previewEnvironment()
}
#endif
