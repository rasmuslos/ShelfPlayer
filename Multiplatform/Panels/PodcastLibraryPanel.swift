//
//  PodcastLibraryView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import ShelfPlayback

@MainActor
@Observable
private final class PodcastLibraryViewModel {
    var library: Library? {
        didSet {
            if library != nil {
                Task {
                    await loadTabs()
                }
            }
        }
    }
    var tabs: [TabValue] = []
    
    func loadTabs() async {
        guard let library else {
            tabs = []
            return
        }
        let tabs = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: .library)
        self.tabs = tabs
    }
}

struct PodcastLibraryPanel: View {
    @Environment(\.library) private var library
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Default(.podcastsAscending) private var podcastsAscending
    @Default(.podcastsSortOrder) private var podcastsSortOrder
    @Default(.podcastsDisplayType) private var podcastsDisplayType
    
    @State private var lazyLoader = LazyLoadHelper<Podcast, String>.podcasts
    @State private var viewModel = PodcastLibraryViewModel()
    
    private var showPlaceholders: Bool {
        !lazyLoader.didLoad
    }
    
    private var libraryRows: some View {
        ForEach(viewModel.tabs, id: \.self) { tab in
            NavigationLink(value: NavigationDestination.tabValue(tab)) {
                Label(tab.label, systemImage: tab.image)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if horizontalSizeClass == .compact && !viewModel.tabs.isEmpty {
                    libraryRows
                        .padding(.horizontal, 20)
                }
                
                if showPlaceholders {
                    VStack(spacing: 0) {
                        if lazyLoader.failed {
                            ErrorView()
                        } else if lazyLoader.working {
                            LoadingView()
                        } else {
                            EmptyCollectionView()
                        }
                    }
                } else {
                    switch podcastsDisplayType {
                    case .grid:
                        PodcastVGrid(podcasts: lazyLoader.items) {
                            lazyLoader.performLoadIfRequired($0)
                        }
                        .padding(.horizontal, 20)
                    case .list:
                        PodcastList(podcasts: lazyLoader.items) {
                            lazyLoader.performLoadIfRequired($0)
                        }
                        .padding(.horizontal, 0)
                    }
                }
            }
        }
        .refreshable {
            lazyLoader.refresh()
        }
        .navigationTitle("panel.library")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "ellipsis") {
                    ItemDisplayTypePicker(displayType: $podcastsDisplayType)
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $podcastsSortOrder, ascending: $podcastsAscending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onChange(of: podcastsAscending) {
            lazyLoader.ascending = podcastsAscending
        }
        .onChange(of: podcastsSortOrder) {
            lazyLoader.sortOrder = podcastsSortOrder
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
            viewModel.library = library
        }
        .onReceive(RFNotification[.invalidateTabs].publisher()) { _ in
            Task {
                await viewModel.loadTabs()
            }
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

