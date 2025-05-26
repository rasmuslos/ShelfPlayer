//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    @State private var libraryPath = NavigationPath()
    @State private var navigateToWhenReady: ItemIdentifier? = nil
    
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
            
            // Update all download & progress trackers
            
            Task.detached {
                await ShelfPlayer.invalidateShortTermCache()
            }
        }
    }
    var isReady: Bool {
        guard let selection = satellite.tabValue else {
            return false
        }
        
        return progressViewModel.importedConnectionIDs.contains(selection.library.connectionID)
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    private var current: Library? {
        guard isCompact else {
            return nil
        }
        
        return satellite.tabValue?.library
    }
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        SyncGate(library: tab.library) {
            NavigationStackWrapper(tab: tab) {
                tab.content
            }
            .modifier(PlaybackTabContentModifier())
            .task {
                ShelfPlayer.updateUIHook()
            }
        }
    }
    
    var body: some View {
        TabView(selection: selectionProxy) {
            if let current {
                ForEach(TabValue.tabs(for: current, isCompact: true)) { tab in
                    Tab(tab.label, systemImage: tab.image, value: tab) {
                        content(for: tab)
                    }
                }
            }
            
            ForEach(connectionStore.flat) { connection in
                if let libraries = connectionStore.libraries[connection.id] {
                    ForEach(libraries) { library in
                        TabSection(library.name) {
                            ForEach(TabValue.tabs(for: library, isCompact: false)) { tab in
                                Tab(tab.label, systemImage: tab.image, value: tab) {
                                    content(for: tab)
                                }
                                .hidden(isCompact)
                            }
                        }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .id(current)
        .modifier(CompactPlaybackModifier(ready: isReady))
        .environment(\.playbackBottomOffset, 52)
        .sensoryFeedback(.error, trigger: progressViewModel.importFailedConnectionIDs)
        .onChange(of: current, initial: true) {
            let appearance = UINavigationBarAppearance()
            
            if current?.type == .audiobooks && Defaults[.enableSerifFont] {
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
        .onChange(of: connectionStore.libraries, initial: true) {
            guard satellite.tabValue == nil, let library = connectionStore.libraries.first?.value.first else {
                return
            }
            
            select(library)
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
        
        switch navigateToWhenReady.type {
        case .audiobook, .author, .narrator, .series:
            guard case .audiobookLibrary(_) = satellite.tabValue else {
                satellite.tabValue = .audiobookLibrary(library)
                return
            }
        case .podcast, .episode:
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
}

#if DEBUG
#Preview {
    TabRouter()
        .previewEnvironment()
}
#endif
