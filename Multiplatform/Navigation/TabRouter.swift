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
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        Group {
            if importedConnectionIDs.contains(tab.library.connectionID) {
                tab.content
                    .modifier(TabContentPlaybackModifier())
                    .task {
                        ShelfPlayer.updateUIHook()
                    }
            } else if importFailedConnectionIDs.contains(tab.library.connectionID) {
                ContentUnavailableView("import.failed", systemImage: "circle.badge.xmark", description: Text("import.failed.description"))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.wiggle, options: .nonRepeating)
                    .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 16) {
                            Button {
                                automaticOfflineModeDeadline = nil
                                RFNotification[.changeOfflineMode].send(true)
                            } label: {
                                if let automaticOfflineModeDeadline {
                                    Text("library.change.automatic")
                                    + Text(automaticOfflineModeDeadline, style: .relative)
                                }
                            }
                            .task {
                                automaticOfflineModeDeadline = .now.addingTimeInterval(4)
                                
                                do {
                                    try await Task.sleep(for: .seconds(4))
                                    
                                    RFNotification[.changeOfflineMode].send(true)
                                    automaticOfflineModeDeadline = nil
                                } catch {
                                    automaticOfflineModeDeadline = nil
                                }
                            }
                            
                            Menu("library.change") {
                                LibraryPicker()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
            } else {
                SessionImporter(connectionID: tab.library.connectionID) {
                    if $0 {
                        importedConnectionIDs.append(tab.library.connectionID)
                    } else {
                        importFailedConnectionIDs.append(tab.library.connectionID)
                    }
                    
                    if importFailedConnectionIDs.count == connectionStore.connections.count {
                        satellite.isOffline = true
                    }
                }
                .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            }
        }
        .animation(.smooth, value: importedConnectionIDs)
        .animation(.smooth, value: importFailedConnectionIDs)
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
        .environment(\.playbackBottomOffset, 88)
        .sensoryFeedback(.error, trigger: importFailedConnectionIDs)
        .onChange(of: current) {
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
    }
    
    private func select(_ library: Library) {
        switch library.type {
        case .audiobooks:
            selection = .audiobookHome(library)
        case .podcasts:
            selection = .podcastHome(library)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var selection: TabValue? = nil

    TabRouter(selection: $selection)
        .previewEnvironment()
}
#endif
