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

    @Environment(ItemNavigationController.self) private var itemNavigationController

    @State private var viewModel = SearchViewModel()
    @State private var availableWidth: CGFloat = 0

    private let targetContentWidth: CGFloat = 720

    private var horizontalRowInset: CGFloat {
        guard horizontalSizeClass == .regular, availableWidth > targetContentWidth else { return 12 }
        return max(12, (availableWidth - targetContentWidth) / 2)
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
                        .listRowInsets(.init(top: 12, leading: horizontalRowInset, bottom: 12, trailing: horizontalRowInset))
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
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: itemNavigationController.search?.0, initial: true) {
            guard let (search, _) = itemNavigationController.consume() else {
                return
            }

            viewModel.search = search
        }
        .onReceive(NavigationEventSource.shared.setGlobalSearch) { search, _ in
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

            let result: [Item]

            do {
                result = try await ShelfPlayerKit.globalSearch(query: search, includeOnlineSearchResults: true)
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
