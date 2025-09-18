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
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    @State private var libraryPath = NavigationPath()
    @State private var navigateToWhenReady: ItemIdentifier? = nil
    
    @AppStorage("io.rfk.shelfPlayer.tabCustomization")
    private var customization: TabViewCustomization
    
    @State private var libraryCompactTabs = [Library: [TabValue]]()
    
    var selectionProxy: Binding<TabValue?> {
        .init() { satellite.tabValue } set: {
            if $0 == satellite.tabValue {
                if case .audiobookLibrary = $0 {
                    RFNotification[.focusSearchField].send()
                } else if case .podcastLibrary = $0 {
                    RFNotification[.focusSearchField].send()
                }
            }
            
            satellite.tabValue = $0
            
            if $0 != nil {
                Defaults[.lastTabValue] = $0
            }
        }
    }
    var isSynchronized: Bool {
        guard let selection = satellite.tabValue else {
            return false
        }
        
        return progressViewModel.importedConnectionIDs.contains(selection.library.connectionID)
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        NavigationStackWrapper(tab: tab) {
            tab.content
                .modifier(PlaybackTabContentModifier())
        }
    }
    
    var body: some View {
        ZStack {
            if isCompact, !isSynchronized, let tabValue = satellite.tabValue {
                SyncGate(library: tabValue.library)
            } else if let tabValue = satellite.tabValue {
                if isCompact, libraryCompactTabs[tabValue.library] == nil {
                    LoadingView()
                        .modifier(OfflineControlsModifier(startOfflineTimeout: true))
                        .task {
                            libraryCompactTabs[tabValue.library] = PersistenceManager.shared.customization.configuredTabs(for: tabValue.library, scope: .tabBar)
                        }
                } else {
                    TabView(selection: selectionProxy) {
                        if let libraryCompactTabs = libraryCompactTabs[tabValue.library] {
                            ForEach(libraryCompactTabs) { tabValue in
                                Tab(tabValue.label, systemImage: tabValue.image, value: tabValue) {
                                    content(for: tabValue)
                                }
                            }
                        }
                        
                        ForEach(connectionStore.connections) { connection in
                            if let libraries = connectionStore.libraries[connection.id] {
                                ForEach(libraries) { library in
                                    TabSection(library.name) {
                                        ForEach(PersistenceManager.shared.customization.availableTabs(for: library)) { tab in
                                            Tab(tab.label, systemImage: tab.image, value: tab) {
                                                if !isSynchronized && !isCompact {
                                                    SyncGate(library: tabValue.library)
                                                } else {
                                                    content(for: tabValue)
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
                    .tabViewCustomization($customization)
                    .tabViewSidebarHeader {
                        Button {
                            satellite.present(.listenNow)
                        } label: {
                            ListenedTodayListRow()
                        }
                        .buttonStyle(.plain)
                    }
                    .tabViewSidebarFooter {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                            
                            Button("panel.search", systemImage: "magnifyingglass") {
                                satellite.present(.globalSearch)
                            }
                            Button("preferences", systemImage: "gearshape.circle") {
                                satellite.present(.preferences)
                            }
                            Button("navigation.offline.enable", systemImage: "network.slash") {
                                RFNotification[.changeOfflineMode].send(payload: true)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .modify {
                        if #available(iOS 26, *) {
                            $0
                                .tabBarMinimizeBehavior(.onScrollDown)
                                .tabViewBottomAccessory {
                                    PlaybackBottomBarPill()
                                }
                        } else {
                            $0
                                .modifier(ApplyLegacyCollapsedForeground())
                        }
                    }
                }
            } else {
                LoadingView()
                    .modifier(OfflineControlsModifier(startOfflineTimeout: false))
                    .onChange(of: connectionStore.libraries, initial: true) {
                        if let lastSelection = Defaults[.lastTabValue] {
                            satellite.tabValue = lastSelection
                            return
                        }
                        
                        guard let library = connectionStore.libraries.first?.value.first else {
                            return
                        }
                        
                        switch library.type {
                            case .audiobooks:
                                satellite.tabValue = .audiobookHome(library)
                            case .podcasts:
                                satellite.tabValue = .podcastHome(library)
                        }
                    }
            }
        }
        .modifier(CompactPlaybackModifier(ready: isSynchronized))
        .environment(\.playbackBottomOffset, 52)
        .sensoryFeedback(.error, trigger: progressViewModel.importFailedConnectionIDs)
        .onChange(of: satellite.tabValue?.library, initial: true) {
            let appearance = UINavigationBarAppearance()
            
            if satellite.tabValue?.library.type == .audiobooks && Defaults[.enableSerifFont] {
                appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
                appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            }
            
            appearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().compactAppearance = appearance
        }
        .onChange(of: satellite.tabValue) {
            navigateIfRequired(withDelay: true)
        }
        .onChange(of: satellite.tabValue?.library) {
            while !libraryPath.isEmpty {
                libraryPath.removeLast()
            }
            
            RFNotification[.performBackgroundSessionSync].send(payload: satellite.tabValue?.library.connectionID)
        }
        .onChange(of: isCompact) {
            libraryCompactTabs.removeAll()
        }
        .onChange(of: connectionStore.libraries, initial: true) {
            populateCompactLibraryTabs()
        }
        .onReceive(RFNotification[.changeLibrary].publisher()) {
            select($0)
        }
        .onReceive(RFNotification[.navigate].publisher()) {
            navigateToWhenReady = $0
            navigateIfRequired(withDelay: false)
        }
        .onReceive(RFNotification[.navigateConditionMet].publisher()) {
            navigateIfRequired(withDelay: true)
        }
    }
    
    private func select(_ library: Library) {
        switch library.type {
            case .audiobooks:
                satellite.tabValue = .audiobookHome(library)
            case .podcasts:
                satellite.tabValue = .podcastHome(library)
        }
    }
    private func navigateIfRequired(withDelay: Bool) {
        guard let navigateToWhenReady else {
            return
        }
        
        guard !satellite.isOffline else {
            self.navigateToWhenReady = nil
            return
        }
        
        guard let library = connectionStore.libraries[navigateToWhenReady.connectionID]?.first(where: { $0.id == navigateToWhenReady.libraryID }) else {
            self.navigateToWhenReady = nil
            return
        }
        
        switch library.type {
            case .audiobooks:
                guard case .audiobookLibrary(_) = satellite.tabValue else {
                    satellite.tabValue = .audiobookLibrary(library)
                    return
                }
            case .podcasts:
                guard case .podcastLibrary(_) = satellite.tabValue else {
                    satellite.tabValue = .podcastLibrary(library)
                    return
                }
        }
        
        guard progressViewModel.importedConnectionIDs.contains(library.connectionID) else {
            if progressViewModel.importFailedConnectionIDs.contains(library.id) {
                self.navigateToWhenReady = nil
            }
            
            return
        }
        
        Task { [navigateToWhenReady] in
            if withDelay {
                try await Task.sleep(for: .seconds(0.5))
            }
            
            await RFNotification[._navigate].send(payload: navigateToWhenReady)
        }
        
        self.navigateToWhenReady = nil
    }
    
    private func populateCompactLibraryTabs() {
        Task {
            for library in connectionStore.libraries.values.flatMap({ $0 }) {
                if libraryCompactTabs[library] == nil {
                    libraryCompactTabs[library] = PersistenceManager.shared.customization.configuredTabs(for: library, scope: .tabBar)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    TabRouter()
        .previewEnvironment()
}
#endif
