//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import RFNotifications
import ShelfPlayerKit

@available(iOS 18, *)
internal struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ConnectionStore.self) private var connectionStore
    
    @Binding var selection: TabValue?
    
    @State private var libraryPath = NavigationPath()
    @State private var automaticOfflineModeDeadline: Date? = nil
    
    @State private var importedConnectionIDs = [String]()
    @State private var importFailedConnectionIDs = [String]()
    
    var selectionProxy: Binding<TabValue?> {
        .init() { selection } set: {
            if $0 == selection, case .search = $0 {
                // NotificationCenter.default.post(name: SearchView.focusNotification, object: nil)
            }
            
            selection = $0
        }
    }
    
    @ViewBuilder
    private func content(for tab: TabValue) -> some View {
        Group {
            if importedConnectionIDs.contains(tab.library.connectionID) {
                tab.content(libraryPath: $libraryPath)
            } else if importFailedConnectionIDs.contains(tab.library.connectionID) {
                ContentUnavailableView("import.failed", systemImage: "circle.badge.xmark", description: Text("import.failed.description"))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.wiggle, options: .nonRepeating)
                    .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 16) {
                            Button {
                                
                            } label: {
                                if let automaticOfflineModeDeadline {
                                    Text("library.change.automatic")
                                    + Text(automaticOfflineModeDeadline, style: .relative)
                                }
                            }
                            .task {
                                automaticOfflineModeDeadline = .now.addingTimeInterval(7)
                                
                                do {
                                    try await Task.sleep(for: .seconds(7))
                                    
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
        // .modifier(NowPlaying.CompactModifier())
        .sensoryFeedback(.error, trigger: importFailedConnectionIDs)
        .onChange(of: current) {
            let appearance = UINavigationBarAppearance()
            
            if current?.type == .audiobooks && Defaults[.useSerifFont] {
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
        default:
            return
        }
    }
}

#Preview {
    @Previewable @State var selection: TabValue? = nil
    
    TabRouter(selection: $selection)
        .environment(ConnectionStore())
}
