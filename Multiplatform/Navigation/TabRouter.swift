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
    
    @Binding var selection: TabValue?
    
    @State private var libraryPath = NavigationPath()
    @State private var automaticOfflineModeDeadline: Date? = nil
    
    @State private var importedConnectionIDs = [String]()
    @State private var importFailedConnectionIDs = [String]()
    
    @State private var navigateToWhenReady: ItemIdentifier? = nil
    
    var selectionProxy: Binding<TabValue?> {
        .init() { selection } set: {
            if $0 == selection {
                if case .audiobookSearch = $0 {
                    RFNotification[.focusSearchField].send()
                } else if case .podcastLibrary = $0 {
                    RFNotification[.focusSearchField].send()
                }
            }
            
            selection = $0
        }
    }
    var isReady: Bool {
        guard let selection else {
            return false
        }
        
        return importedConnectionIDs.contains(selection.library.connectionID)
    }
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    private var current: Library? {
        guard isCompact else {
            return nil
        }
        
        return selection?.library
    }
    private var connectionID: ItemIdentifier.ConnectionID? {
        selection?.library.connectionID
    }
    
    @ViewBuilder
    private var syncFailedContent: some View {
        ContentUnavailableView("navigation.sync.failed", systemImage: "circle.badge.xmark", description: Text("navigation.sync.failed"))
            .symbolRenderingMode(.multicolor)
            .symbolEffect(.wiggle, options: .nonRepeating)
            .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 16) {
                    Button {
                        automaticOfflineModeDeadline = nil
                        RFNotification[.changeOfflineMode].send(payload: true)
                    } label: {
                        if let automaticOfflineModeDeadline {
                            Text("navigation.offline.automatic")
                            + Text(automaticOfflineModeDeadline, style: .relative)
                        }
                    }
                    .task {
                        automaticOfflineModeDeadline = .now.addingTimeInterval(7)
                        
                        do {
                            try await Task.sleep(for: .seconds(7))
                            
                            await RFNotification[.changeOfflineMode].send(payload: true)
                            automaticOfflineModeDeadline = nil
                        } catch {
                            automaticOfflineModeDeadline = nil
                        }
                    }
                    
                    Menu("navigation.library.select") {
                        LibraryPicker()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
    }
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        @Bindable var satellite = satellite
        
        Group {
            if importedConnectionIDs.contains(tab.library.connectionID) {
                tab.content
                    .modifier(PlaybackTabContentModifier())
                    .task {
                        ShelfPlayer.updateUIHook()
                    }
            } else if importFailedConnectionIDs.contains(tab.library.connectionID) {
                syncFailedContent
            } else {
                UserDataSynchroniser(connectionID: tab.library.connectionID) {
                    if $0 {
                        importedConnectionIDs.append(tab.library.connectionID)
                        importFailedConnectionIDs.removeAll(where: { $0 == tab.library.connectionID })
                    } else {
                        importFailedConnectionIDs.append(tab.library.connectionID)
                        importedConnectionIDs.removeAll(where: { $0 == tab.library.connectionID })
                    }
                    
                    if importFailedConnectionIDs.count == connectionStore.connections.count {
                        satellite.isOffline = true
                    }
                    
                    navigateIfRequired(withDelay: true)
                }
                .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            }
        }
        .animation(.smooth, value: importedConnectionIDs)
        .animation(.smooth, value: importFailedConnectionIDs)
    }
    
    var body: some View {
        TabView(selection: selectionProxy) {
            if let current {
                ForEach(TabValue.tabs(for: current)) { tab in
                    Tab(tab.label, systemImage: tab.image, value: tab) {
                        content(for: tab)
                    }
                }
            }
            ForEach(connectionStore.flat) { connection in
                if let libraries = connectionStore.libraries[connection.id] {
                    TabSection(connection.user) {
                        ForEach(libraries) {
                            ForEach(TabValue.tabs(for: $0)) { tab in
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
        .sensoryFeedback(.error, trigger: importFailedConnectionIDs)
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
        .onChange(of: selection) {
            navigateIfRequired(withDelay: true)
        }
        .onChange(of: selection?.library) {
            while !libraryPath.isEmpty {
                libraryPath.removeLast()
            }
        }
        .onChange(of: connectionStore.libraries, initial: true) {
            guard selection == nil, let library = connectionStore.libraries.first?.value.first else { return }
            
            select(library)
        }
        .onReceive(RFNotification[.changeLibrary].publisher()) {
            select($0)
        }
        .onReceive(RFNotification[.navigateNotification].publisher()) {
            navigateToWhenReady = $0
            navigateIfRequired(withDelay: false)
        }
    }
    
    private func select(_ library: Library) {
        switch library.type {
        case .audiobooks:
            selection = .audiobookHome(library)
        case .podcasts:
            selection = .podcastHome(library)
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
        case .audiobook, .author, .series:
            guard case .audiobookLibrary(_) = selection else {
                selection = .audiobookLibrary(library)
                return
            }
        case .podcast, .episode:
            guard case .podcastLibrary(_) = selection else {
                selection = .podcastLibrary(library)
                return
            }
        }
        
        guard importedConnectionIDs.contains(library.connectionID) else {
            if importFailedConnectionIDs.contains(library.id) {
                self.navigateToWhenReady = nil
            }
            
            return
        }
        
        Task { [navigateToWhenReady] in
            if withDelay {
                try await Task.sleep(for: .seconds(0.5))
            }
            
            await RFNotification[._navigateNotification].send(payload: navigateToWhenReady)
        }
        
        self.navigateToWhenReady = nil
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: TabValue? = nil

    TabRouter(selection: $selection)
        .previewEnvironment()
}
#endif
