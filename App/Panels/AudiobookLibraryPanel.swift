//
//  AudiobookLibraryPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct AudiobookLibraryPanel: View {
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library

    @Bindable private var settings = AppSettings.shared

    @FocusState private var focused: Bool

    @State private var id = UUID()
    @State private var viewModel = LibraryViewModel()

    private var libraryRowCount: CGFloat {
        horizontalSizeClass == .compact && library != nil
        ? viewModel.tabs.isEmpty ? 0 : CGFloat(viewModel.tabs.count)
        : 0
    }

    @ViewBuilder
    private var libraryRows: some View {
        if horizontalSizeClass == .compact {
            if !viewModel.tabs.isEmpty {
                ForEach(Array(viewModel.tabs.enumerated()), id: \.element) { (index, row) in
                    NavigationLink(value: NavigationDestination.tabValue(row)) {
                        Label {
                            Text(row.label)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: row.image)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .listRowSeparator(index == 0 ? .hidden : .automatic, edges: .top)
                }
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

            PanelItemCountLabel(total: viewModel.lazyLoader.totalCount, type: .none, isLoading: viewModel.lazyLoader.isLoading)
        }
        .id(id)
    }

    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            libraryRowsList

            AudiobookVGrid(sections: viewModel.lazyLoader.items) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
            .id(id)
            .padding(.top, 12)
            .padding(.horizontal, 20)

            PanelItemCountLabel(total: viewModel.lazyLoader.totalCount, type: .none, isLoading: viewModel.lazyLoader.isLoading)
        }
    }

    @ViewBuilder
    private var searchPresentation: some View {
        if let results = viewModel.searchResults {
            if results.isEmpty {
                ContentUnavailableView.search(text: viewModel.search)
            } else {
                List {
                    ForEach(results) { item in
                        Button {
                            NavigationEventSource.shared.navigate.send(item.id)
                        } label: {
                            ItemCompactRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
                    }
                }
                .listStyle(.plain)
            }
        } else if viewModel.isSearching {
            LoadingView()
        } else {
            ContentUnavailableView.search(text: viewModel.search)
        }
    }

    var body: some View {
        Group {
            if viewModel.isSearchActive {
                searchPresentation
            } else if viewModel.showPlaceholders {
                ScrollView {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal, .vertical])

                        VStack(spacing: 0) {
                            libraryRowsList
                                .frame(alignment: .top)

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
                switch viewModel.displayType {
                case .grid:
                    gridPresentation
                case .list:
                    listPresentation
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("panel.library")
        .largeTitleDisplayMode()
        .searchable(text: $viewModel.search, placement: .navigationBarDrawer)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease" : "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)

                    Divider()

                    Section("item.filter") {
                        ItemFilterPicker(filter: $viewModel.filter, restrictToPersisted: $viewModel.restrictToPersisted)
                    }

                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
                    }

                    Divider()

                    Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                        satellite.present(.customizeLibrary(viewModel.library, .library))
                    }

                    Toggle("item.groupAudiobooksBySeries", systemImage: "square.3.layers.3d.down.forward", isOn: $settings.groupAudiobooksInSeries)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .hapticFeedback(.error, trigger: viewModel.notifyError)
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
        .onReceive(TabEventSource.shared.invalidateTabs) {
            viewModel.loadTabs()
        }
    }
}

// MARK: - View Model

@MainActor @Observable
private final class LibraryViewModel {
    var filter: ItemFilter {
        didSet { AppSettings.shared.audiobooksFilter = filter }
    }
    var restrictToPersisted: Bool {
        didSet { AppSettings.shared.audiobooksRestrictToPersisted = restrictToPersisted }
    }
    var displayType: ItemDisplayType {
        didSet { AppSettings.shared.audiobooksDisplayType = displayType }
    }

    var sortOrder: AudiobookSortOrder {
        didSet { AppSettings.shared.audiobooksSortOrder = sortOrder }
    }
    var ascending: Bool {
        didSet { AppSettings.shared.audiobooksAscending = ascending }
    }

    var tabs = [TabValue]()

    let lazyLoader = LazyLoadHelper<Audiobook, AudiobookSortOrder>.audiobooks

    var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }

    var search = "" {
        didSet { performSearch() }
    }
    var searchResults: [Item]?
    private var searchTask: Task<Void, Never>?

    private(set) var notifyError = false

    init() {
        let settings = AppSettings.shared
        filter = settings.audiobooksFilter
        restrictToPersisted = settings.audiobooksRestrictToPersisted
        displayType = settings.audiobooksDisplayType
        sortOrder = settings.audiobooksSortOrder
        ascending = settings.audiobooksAscending
    }

    // MARK: Helper

    var showPlaceholders: Bool {
        !lazyLoader.didLoad
    }

    var isLoading: Bool {
        lazyLoader.working && !lazyLoader.failed
    }

    var isSearchActive: Bool {
        !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isSearching: Bool {
        searchTask != nil
    }

    func load() {
        loadTabs()
    }

    func refresh() {
        lazyLoader.refresh()

        loadTabs()
    }

    func loadTabs() {
        Task {
            tabs = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .library)
        }
    }

    private func performSearch() {
        searchTask?.cancel()

        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty, let library else {
            searchResults = nil
            searchTask = nil
            return
        }

        searchTask = Task {
            do {
                try await Task.sleep(for: .seconds(0.5))
                try Task.checkCancellation()

                let grouped = try await ABSClient[library.id.connectionID].items(in: library.id, search: query)
                let presort: [Item] = grouped.0 + grouped.1 + grouped.2 + grouped.3
                let sorted = presort.sorted { $0.name.levenshteinDistanceScore(to: query) > $1.name.levenshteinDistanceScore(to: query) }

                try Task.checkCancellation()

                withAnimation {
                    self.searchResults = sorted
                    self.searchTask = nil
                }
            } catch is CancellationError {
                // overridden by a newer search; leave previous results in place
            } catch {
                withAnimation {
                    self.notifyError.toggle()
                    self.searchResults = []
                    self.searchTask = nil
                }
            }
        }
    }
}

// MARK: - Scopes

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
            "item.author"
        case .narrators:
            "item.narrator"
        case .audiobooks:
            "item.audiobook"
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
    .environment(\.library, .init(id: "fixture", connectionID: "fixture", name: "Fixture", type: "book", index: 0))
}
#endif
