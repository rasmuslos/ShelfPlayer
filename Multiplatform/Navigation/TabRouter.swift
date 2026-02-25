//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import SwiftUI
import ShelfPlayback

struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(ItemNavigationController.self) private var itemNavigationController
    
    @AppStorage("io.rfk.shelfPlayer.tabCustomization")
    private var customization: TabViewCustomization
    @Default(.lastPlayedItemID) private var lastPlayedItemID
    
    @State private var viewModel = TabRouterViewModel()
    @State private var listenedTodayTracker = ListenedTodayTracker.shared
    
    var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    var isCompactAndReady: Bool {
        if isCompact {
            viewModel.tabValue != nil
        } else {
            false
        }
    }
    var isNowPlayingBarVisible: Bool {
        guard let selectedLibraryID = viewModel.selectedLibraryID else {
            return false
        }
        
        guard viewModel.currentConnectionStatus[selectedLibraryID.connectionID] == true else {
            return false
        }
        
        return satellite.nowPlayingItemID != nil || lastPlayedItemID != nil
    }
    
    var connections: [FriendlyConnection] {
        connectionStore.connections
    }
    var onlineConnections: [FriendlyConnection] {
        connections.filter { !isOffline($0.id) }
    }
    var offlineConnections: [ItemIdentifier.ConnectionID] {
        connectionStore.offlineConnections
    }
    func isOffline(_ id: ItemIdentifier.ConnectionID) -> Bool {
        offlineConnections.contains(id)
    }
    
    var isAtLeastOneConnectionSynchronized: Bool {
        viewModel.currentConnectionStatus.values.contains(true)
    }
    
    @ViewBuilder
    private func loadingView(startOfflineTimeout: Bool) -> some View {
        LoadingView()
            .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            .modifier(OfflineControlsModifier(startOfflineTimeout: startOfflineTimeout))
    }
    private func loadingTab(task: (() async -> Void)? = nil) -> some TabContent<TabValue?> {
        Tab("loading", systemImage: "teddybear.fill", value: .loading) {
            loadingView(startOfflineTimeout: true)
                .task {
                    await task?()
                }
        }
    }
    @ViewBuilder
    private func errorView(startOfflineTimeout: Bool) -> some View {
        ErrorView()
            .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            .modifier(OfflineControlsModifier(startOfflineTimeout: startOfflineTimeout))
    }
    
    @ViewBuilder
    static func panel(for tab: TabValue) -> some View {
        switch tab {
            case .audiobookHome:
                AudiobookHomePanel()
            case .audiobookSeries:
                AudiobookSeriesPanel()
            case .audiobookAuthors:
                AudiobookAuthorsPanel()
            case .audiobookNarrators:
                AudiobookNarratorsPanel()
            case .audiobookBookmarks:
                AudiobookBookmarksPanel()
            case .audiobookCollections:
                CollectionsPanel(type: .collection)
            case .podcastLibrary:
                PodcastLibraryPanel()
                
            case .podcastHome:
                PodcastHomePanel()
            case .podcastLatest:
                PodcastLatestPanel()
            case .audiobookLibrary:
                AudiobookLibraryPanel()
                
            case .collection(let collection, _):
                CollectionView(collection)
            case .playlists:
                CollectionsPanel(type: .playlist)
                
            case .downloaded:
                DownloadedPanel()
                
            case .custom(let tabValue, _):
                AnyView(erasing: panel(for: tabValue))
                
            default:
                fatalError()
        }
    }
    private func tab(for tab: TabValue) -> some TabContent<TabValue?> {
        Tab(tab.label, systemImage: tab.image, value: tab) {
            if let libraryID = tab.libraryID, let library = viewModel.libraryLookup[libraryID] {
                if let isSynchronized = viewModel.currentConnectionStatus[libraryID.connectionID] {
                    if isSynchronized {
                        NavigationStackWrapper(tab: tab) {
                            Self.panel(for: tab)
                        }
                        .environment(\.library, library)
                        .modifier(PlaybackTabContentModifier())
                    } else {
                        errorView(startOfflineTimeout: true)
                    }
                } else {
                    loadingView(startOfflineTimeout: true)
                        .task {
                            viewModel.synchronize(connectionID: libraryID.connectionID)
                        }
                }
            } else {
                errorView(startOfflineTimeout: false)
            }
        }
    }
    
    private func tabCustomizationID(for tab: TabValue) -> String {
        "tab_\(tab.id)"
    }
    private func libraryCustomizationID(for library: LibraryIdentifier) -> String {
        "library_\(library.id)"
    }
    private func sidebarSectionLabel(for library: Library, connection: FriendlyConnection) -> String {
        if onlineConnections.count == 1 {
            library.name
        } else {
            "\(library.name) (\(connection.name))"
        }
    }

    private func sidebarTabs() -> some TabContent<TabValue?> {
        ForEach(onlineConnections) { connection in
            if let libraries = viewModel.connectionLibraries[connection.id] {
                ForEach(libraries) { library in
                    if let sideBarTabs = viewModel.sideBar[library.id] {
                        TabSection(sidebarSectionLabel(for: library, connection: connection)) {
                            ForEach(sideBarTabs) {
                                tab(for: $0)
                                    .customizationID(tabCustomizationID(for: $0))
                            }
                        }
                        .customizationID(libraryCustomizationID(for: library.id))
                    }
                }
            }
        }
    }

    var body: some View {
        TabView(selection: $viewModel.tabValue) {
            if viewModel.connectionLibraries.isEmpty {
                loadingTab {
                    await viewModel.loadLibraries()
                }
            } else if isCompact, !isCompactAndReady {
                loadingTab() {
                    viewModel.selectLastOrFirstCompactLibrary()
                }
            } else if !isCompact, viewModel.tabValue == nil {
                loadingTab() {
                    viewModel.selectLastOrFirstSidebarLibrary()
                }
            } else {
                if isCompact {
                    // Compact
                    if let selectedLibraryID = viewModel.selectedLibraryID, let tabBar = viewModel.tabBar[selectedLibraryID] {
                        ForEach(tabBar) {
                            tab(for: $0)
                        }
                        .hidden(!isCompactAndReady || viewModel.pinnedTabsActive)
                    }
                } else {
                    // Sidebar
                    sidebarTabs()
                }
                
                // Pinned
                ForEach(viewModel.pinnedTabValues) {
                    tab(for: $0)
                }
                .hidden(isCompact ? !viewModel.pinnedTabsActive && isCompactAndReady : false)
                                
                // Search
                Tab(value: .search, role: .search) {
                    NavigationStack {
                        SearchPanel()
                    }
                }
                .hidden(isCompact ? !isCompactAndReady : false)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
        .modify {
            if #available(iOS 26, *) {
                $0
                    .tabBarMinimizeBehavior(.onScrollDown)
            } else {
                $0
            }
        }
        .modify {
            if isCompact, #available(iOS 26.1, *) {
                $0
                    .tabViewBottomAccessory(isEnabled: isNowPlayingBarVisible) {
                        if satellite.nowPlayingItemID != nil {
                            PlaybackBottomBarPill()
                        } else if let lastPlayedItemID {
                            PlaybackPlaceholderBottomPill(itemID: lastPlayedItemID)
                        }
                    }
            } else {
                $0
                    .modifier(ApplyLegacyCollapsedForeground(isEnabled: isNowPlayingBarVisible))
            }
        }
        .modifier(CompactPlaybackModifier())
        .modifier(RegularPlaybackModifier())
        .environment(viewModel)
        .environment(\.optionalTabRouter, viewModel)
        .environment(listenedTodayTracker)
        .environment(\.playbackBottomOffset, 52)
        .onChange(of: itemNavigationController.itemID, initial: true) {
            guard let itemID: ItemIdentifier = itemNavigationController.consume() else {
                return
            }
            
            let targetLibraryID = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
            if viewModel.tabValue?.libraryID != targetLibraryID {
                if isCompact {
                    viewModel.selectFirstCompactTab(for: targetLibraryID, allowPinned: true)
                } else {
                    viewModel.selectFirstSidebarTab(for: targetLibraryID, allowPinned: true)
                }
            }
            
            viewModel.navigateToWhenReady = itemID
            navigateToWaitingItemID()
        }
        .onChange(of: viewModel.tabValue) {
            navigateToWaitingItemID()
        }
        .onChange(of: viewModel.currentConnectionStatus) {
            navigateToWaitingItemID()
        }
        .onChange(of: itemNavigationController.search?.0, initial: true) {
            navigateToWaitingSearch()
        }
        .onChange(of: viewModel.selectedLibraryID) {
           navigateToWaitingSearch()
        }
        .onChange(of: isAtLeastOneConnectionSynchronized, initial: true) {
            guard isAtLeastOneConnectionSynchronized else {
                return
            }
            
            ShelfPlayer.initOnlineUIHook()
        }
    }
    
    func navigateToWaitingItemID() {
        guard let libraryID = viewModel.tabValue?.libraryID, let navigateToWhenReady = viewModel.navigateToWhenReady else {
            return
        }
        
        guard viewModel.currentConnectionStatus[navigateToWhenReady.connectionID] == true else {
            return
        }
        
        guard libraryID == .convertItemIdentifierToLibraryIdentifier(navigateToWhenReady) else {
            return
        }
        
        viewModel.navigateToWhenReady = nil
        
        Task {
            try await Task.sleep(for: .seconds(0.4))
            await RFNotification[._navigate].send(payload: navigateToWhenReady)
        }
    }
    func navigateToWaitingSearch() {
        guard viewModel.selectedLibraryID != nil, itemNavigationController.search != nil else {
            return
        }
        
        viewModel.tabValue = .search
    }
}

struct OptionalTabRouterEnvironmentKey: EnvironmentKey {
    public static let defaultValue: TabRouterViewModel? = nil
}

extension EnvironmentValues {
    var optionalTabRouter: TabRouterViewModel? {
        get { self[OptionalTabRouterEnvironmentKey.self] }
        set { self[OptionalTabRouterEnvironmentKey.self] = newValue }
    }
}

/*

    var body: some View {
        applyEvents {
            ZStack {
                
                            ForEach(connectionStore.connections) { connection in
                                if let libraries = connectionStore.libraries[connection.id] {
                                    ForEach(libraries) { library in
                                        TabSection(library.name) {
                                            ForEach(PersistenceManager.shared.customization.availableTabs(for: library, scope: .sidebar)) { tab in
                                                Tab(tab.label, systemImage: tab.image, value: tab) {
                                                    if !isSynchronized && !isCompact {
                                                        SyncGate(library: tabValue.library)
                                                    } else {
                                                        content(for: tab)
                                                    }
                                                }
                                                .hidden(isCompact)
                                                .customizationID("tab_\(library.id)_\(library.connectionID)_\(tab.id)")
                                            }
                                        }
                                        .customizationID("library_\(library.id)_\(library.connectionID)")
                                    }
                                }
                            }
                            
                        }
                        .tabViewSidebarFooter {
                            Divider()
                                .padding(.bottom, 12)
                            
                            HStack(spacing: 12) {
                                Button("preferences", systemImage: "gearshape") {
                                    satellite.present(.preferences)
                                }
                                
                                Button("navigation.offline.enable", systemImage: "network.slash") {
                                    OfflineMode.shared.setEnabled(true)
                                }
                                
                                Spacer()
                            }
                            .buttonStyle(.plain)
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.primary)
                        }
                        .tabViewSidebarHeader {
                            Button {
                                satellite.present(.listenNow)
                            } label: {
                                ListenedTodayListRow()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
 */

#if DEBUG
#Preview {
    TabRouter()
        .previewEnvironment()
}
#endif
