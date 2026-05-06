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

    @Environment(TabRouterViewModel.self) private var tabRouterViewModel
    @Environment(ItemNavigationController.self) private var itemNavigationController

    @State private var viewModel = SearchViewModel()
    @State private var availableWidth: CGFloat = 0

    private let targetContentWidth: CGFloat = 720

    private var horizontalRowInset: CGFloat {
        guard horizontalSizeClass == .regular, availableWidth > targetContentWidth else { return 20 }
        return max(20, (availableWidth - targetContentWidth) / 2)
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        availableWidth = proxy.size.width
                    }
            }
            .frame(height: 0)

            if let result = viewModel.result {
                List {
                    ForEach(result) { item in
                        Button {
                            NavigationEventSource.shared.navigate.send(item.id)
                        } label: {
                            ItemCompactRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
                        .listRowInsets(.init(top: 0, leading: horizontalRowInset, bottom: 0, trailing: horizontalRowInset))
                        .alignmentGuide(.listRowSeparatorLeading) { _ in horizontalRowInset }
                        .alignmentGuide(.listRowSeparatorTrailing) { d in d[.trailing] - horizontalRowInset }
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
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer)
        .searchScopes($viewModel.scope, activation: horizontalSizeClass == .compact ? .onSearchPresentation : .onTextEntry) {
            if let library = viewModel.library {
                Text(verbatim: "\"\(library.name)\"")
                    .tag(SearchViewModel.SearchScope.library)
            }

            Text("panel.search.global")
                .tag(SearchViewModel.SearchScope.global)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if horizontalSizeClass == .compact {
                    CompactLibraryPicker()
                } else {
                    Menu {
                        LibraryPicker()
                    } label: {
                        Label("navigation.library.select", systemImage: "books.vertical.fill")
                    }
                }
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: tabRouterViewModel.library, initial: true) {
            viewModel.library = tabRouterViewModel.library
        }
        .onChange(of: itemNavigationController.search?.0, initial: true) {
            guard let (search, scope) = itemNavigationController.consume() else {
                return
            }

            viewModel.search = search
            viewModel.scope = scope
        }
        .onReceive(NavigationEventSource.shared.setGlobalSearch) { search, scope in
            viewModel.scope = scope

            Task {
                try? await Task.sleep(for: .seconds(0.6))
                viewModel.search = search
            }
        }
        .hapticFeedback(.error, trigger: viewModel.notifyError)
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

    var library: Library? {
        didSet {
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
        debounceTask = Task {
            #if DEBUG && false
            withAnimation {
                self.result = [
                    Audiobook.fixture,
                    Series.fixture,

                    Episode.fixture,
                    Podcast.fixture,

                    Person.authorFixture,
                    Person.narratorFixture,

                    ItemCollection.collectionFixture,
                    ItemCollection.playlistFixture,
                ]
            }

            return
            #endif

            do {
                try await Task.sleep(for: .seconds(1.2))
                try Task.checkCancellation()
            } catch {
                self.logger.error("Failed to sleep: \(error)")
                return
            }

            let search = self.search.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !search.isEmpty else {
                withAnimation {
                    self.result = nil
                    self.debounceTask = nil
                }

                return
            }

            let scope = self.scope
            let result: [Item]

            do {
                switch scope {
                case .library:
                    guard let library = self.library else {
                        throw APIClientError.notFound
                    }

                    let grouped = try await ABSClient[library.id.connectionID].items(in: library.id, search: search)
                    let part = grouped.4 + grouped.5
                    let presort = grouped.0 + grouped.1 + grouped.2 + grouped.3 + part

                    result = presort.sorted { $0.name.levenshteinDistanceScore(to: search) > $1.name.levenshteinDistanceScore(to: search) }
                case .global:
                    result = try await ShelfPlayerKit.globalSearch(query: search, includeOnlineSearchResults: true)
                }
            } catch {
                self.logger.error("Failed to search: \(error)")

                withAnimation {
                    self.notifyError.toggle()
                    self.debounceTask = nil
                }

                return
            }

            withAnimation {
                self.debounceTask = nil
                self.result = result
            }
        }
    }

    typealias SearchScope = GlobalSearchScope
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
    .previewEnvironment()
}
#endif
