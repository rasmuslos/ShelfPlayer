//
//  PodcastLibraryPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

struct PodcastLibraryPanel: View {
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library

    @Environment(Satellite.self) private var satellite

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

            PodcastList(podcasts: viewModel.filteredPodcasts) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }

            PanelItemCountLabel(total: viewModel.lazyLoader.totalCount, type: .podcast, isLoading: viewModel.lazyLoader.isLoading)
        }
        .id(id)
        .listStyle(.plain)
    }

    @ViewBuilder
    private var gridPresentation: some View {
        ScrollView {
            libraryRowsList

            PodcastVGrid(podcasts: viewModel.filteredPodcasts) {
                viewModel.lazyLoader.performLoadIfRequired($0)
            }
            .id(id)
            .padding(.top, 12)
            .padding(.horizontal, 20)

            PanelItemCountLabel(total: viewModel.lazyLoader.totalCount, type: .podcast, isLoading: viewModel.lazyLoader.isLoading)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: viewModel.filter != .all ? "line.3.horizontal.decrease" : "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $viewModel.displayType)

                    Divider()

                    Section("item.filter") {
                        PodcastFilterPicker(filter: $viewModel.filter)
                    }

                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
                    }

                    if let library {
                        Divider()

                        Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                            satellite.present(.customizeLibrary(library, .library))
                        }
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: viewModel.sortOrder) {
            viewModel.lazyLoader.sortOrder = viewModel.sortOrder
        }
        .onChange(of: viewModel.ascending) {
            viewModel.lazyLoader.ascending = viewModel.ascending
        }
        .task {
            viewModel.loadTabs()
        }
        .refreshable {
            viewModel.refresh()
        }
        .onAppear {
            viewModel.library = library
            viewModel.lazyLoader.initialLoad()
        }
        .onReceive(TabEventSource.shared.invalidateTabs) { _ in
            viewModel.loadTabs()
        }
    }
}

// MARK: - View Model

@MainActor @Observable
private final class LibraryViewModel {
    var filter: PodcastFilter {
        didSet { AppSettings.shared.podcastsFilter = filter }
    }
    var displayType: ItemDisplayType {
        didSet { AppSettings.shared.podcastsDisplayType = displayType }
    }

    var sortOrder: PodcastSortOrder {
        didSet { AppSettings.shared.podcastsSortOrder = sortOrder }
    }
    var ascending: Bool {
        didSet { AppSettings.shared.podcastsAscending = ascending }
    }

    var tabs = [TabValue]()

    let lazyLoader = LazyLoadHelper<Podcast, PodcastSortOrder>.podcasts

    var library: Library? {
        didSet {
            lazyLoader.library = library
        }
    }

    init() {
        let settings = AppSettings.shared
        filter = settings.podcastsFilter
        displayType = settings.podcastsDisplayType
        sortOrder = settings.podcastsSortOrder
        ascending = settings.podcastsAscending
    }

    var filteredPodcasts: [Podcast] {
        switch filter {
        case .all:
            lazyLoader.items
        case .unfinished:
            lazyLoader.items.filter { ($0.incompleteEpisodeCount ?? 0) > 0 }
        case .finished:
            lazyLoader.items.filter { ($0.incompleteEpisodeCount ?? -1) == 0 }
        }
    }

    var showPlaceholders: Bool {
        !lazyLoader.didLoad
    }

    var isLoading: Bool {
        lazyLoader.working && !lazyLoader.failed
    }

    func refresh() {
        lazyLoader.refresh()
        loadTabs()
    }

    func loadTabs() {
        Task {
            guard let library else {
                return
            }

            tabs = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .library)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastLibraryPanel()
    }
    .previewEnvironment()
}
#endif
