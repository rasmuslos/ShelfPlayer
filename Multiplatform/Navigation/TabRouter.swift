//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    @Environment(ConnectionStore.self) private var connectionStore
    
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
            viewModel.selectedLibraryID != nil
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
    var offlineConnections: [ItemIdentifier.ConnectionID] {
        connectionStore.offlineConnections
    }
    func isOffline(_ id: ItemIdentifier.ConnectionID) -> Bool {
        offlineConnections.contains(id)
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
                
            case .playlists:
                CollectionsPanel(type: .playlist)
                
            case .collection(let collection, _):
                CollectionView(collection)
                
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
    
    var body: some View {
        TabView(selection: $viewModel.tabValue) {
            if viewModel.connectionLibraries.isEmpty {
                loadingTab {
                    await viewModel.loadLibraries()
                }
            } else {
                // Select first
                loadingTab() {
                    viewModel.selectLastOrFirstCompactLibrary()
                }
                .hidden(isCompactAndReady)
                
                // Compact
                if let selectedLibraryID = viewModel.selectedLibraryID, let tabBar = viewModel.tabBar[selectedLibraryID] {
                    ForEach(tabBar) {
                        tab(for: $0)
                    }
                    .hidden(!isCompactAndReady || viewModel.pinnedTabsActive)
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
                .hidden(!isCompactAndReady)
            }
            
//            ForEach(connections) { connection in
//                TabSection {
//                    if isOffline(connection.id) {
//                        Tab(value: .loading) {
//                            Text(":(")
//                        }
//                    } else {
//                        Tab(value: .loading) {
//                            Text(":)")
//                        }
//                    }
//                } header: {
//                    Text(connection.name)
//                }
//            }
//            .hidden(isCompact)
        }
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
        .environment(listenedTodayTracker)
        .environment(\.playbackBottomOffset, 52)
        .onAppear {
            ShelfPlayer.initOnlineUIHook()
        }
    }
}

/*
struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    @State private var viewModel = TabRouterViewModel()
    
    @AppStorage("io.rfk.shelfPlayer.tabCustomization")
    private var customization: TabViewCustomization
    
    @Default(.customTabValues) private var customTabValues
    @Default(.customTabsActive) private var customTabsActive
    
    var isSynchronized: Bool {
        guard let selection = viewModel.tabValue else {
            return false
        }
        
        return progressViewModel.importedConnectionIDs.contains(selection.library.connectionID)
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    private var searchTab: TabValue? {
        viewModel.searchTab(for: viewModel.tabValue)
    }
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        if case .custom(let wrapped) = tab {
            AnyView(erasing: content(for: wrapped))
        } else {
            NavigationStackWrapper(tab: tab) {
                tab.content
            }
            .modifier(PlaybackTabContentModifier())
        }
    }
    
    @ViewBuilder
    private func applyChangeEvents(_ content: () -> some View) -> some View {
        content()
            .onChange(of: viewModel.tabValue) {
                viewModel.navigateIfRequired(withDelay: true, customTabValues: customTabValues, setCustomTabsActive: { customTabsActive = $0 })
            }
            .onChange(of: viewModel.tabValue?.library.connectionID) {
                RFNotification[.performBackgroundSessionSync].send(payload: viewModel.tabValue?.library.connectionID)
            }
            .onChange(of: customTabValues) {
                if customTabValues.isEmpty {
                    customTabsActive = false
                }
            }
    }
    @ViewBuilder
    private func applyReceiveEvents(_ content: () -> some View) -> some View {
        content()
            .onReceive(RFNotification[.changeLibrary].publisher()) { (library: Library) in
                viewModel.select(library)
            }
            .onReceive(RFNotification[.setGlobalSearch].publisher()) { payload in
                guard let library = viewModel.tabValue?.library, viewModel.tabValue != searchTab else {
                    return
                }
                
                viewModel.tabValue = .search(library)
                
                Task {
                    try await Task.sleep(for: .seconds(0.6))
                    RFNotification[.setGlobalSearch].dispatch(payload: payload)
                }
            }
            .onReceive(RFNotification[.navigate].publisher()) { (id: ItemIdentifier) in
                viewModel.navigateToWhenReady = id
                viewModel.navigateIfRequired(withDelay: false, customTabValues: customTabValues, setCustomTabsActive: { customTabsActive = $0 })
            }
            .onReceive(RFNotification[.navigateConditionMet].publisher()) { _ in
                viewModel.navigateIfRequired(withDelay: true, customTabValues: customTabValues, setCustomTabsActive: { customTabsActive = $0 })
            }
    }
    @ViewBuilder
    
    var body: some View {
        applyEvents {
            ZStack {
                if isCompact, !isSynchronized, let tabValue = viewModel.tabValue {
                    SyncGate(library: tabValue.library)
                } else if let tabValue = viewModel.tabValue {
                    if isCompact, viewModel.libraryCompactTabs[tabValue.library] == nil {
                        LoadingView()
                            .modifier(OfflineControlsModifier(startOfflineTimeout: true))
                            .task {
                                await viewModel.configureTabsIfNeeded(for: tabValue.library)
                            }
                    } else {
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
                        .tabViewStyle(.sidebarAdaptable)
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
                        .tabViewCustomization($customization)
                        .tabViewSidebarHeader {
                            Button {
                                satellite.present(.listenNow)
                            } label: {
                                ListenedTodayListRow()
                            }
                            .buttonStyle(.plain)
                        }
                        .onAppear {
                            viewModel.navigateIfRequired(withDelay: true, customTabValues: customTabValues, setCustomTabsActive: { customTabsActive = $0 })
                        }
                    }
 }
            }
            .sensoryFeedback(.error, trigger: progressViewModel.importFailedConnectionIDs)
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

