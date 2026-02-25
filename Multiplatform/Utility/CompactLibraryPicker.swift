//
//  CompactLibraryPicker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.01.26.
//

import SwiftUI
import ShelfPlayback

struct CompactLibraryPicker: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.library) private var library
    
    @Environment(TabRouterViewModel.self) private var tabRouterViewModel
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    var customizeLibrary = false
    
    private var offlineConnections: [ItemIdentifier.ConnectionID] {
        Array(tabRouterViewModel.currentConnectionStatus.filter { !$1 }.keys)
    }
    
    private var pinnedTabsBinding: Binding<Bool> {
        .init {
            tabRouterViewModel.pinnedTabsActive
        } set: {
            if $0 {
                tabRouterViewModel.enableFirstPinnedTab()
            } else {
                tabRouterViewModel.enableFirstLibrary(scope: .tabBar)
            }
        }
    }
    
    var body: some View {
        Menu {
            Toggle(isOn: pinnedTabsBinding) {
                Label("panel.home", image: "shelfPlayer.fill")
            }
            
            Button("navigation.offline.enable", systemImage: "network.slash") {
                OfflineMode.shared.forceEnable()
            }
            
            Divider()

            if !tabRouterViewModel.pinnedTabsActive {
                LibraryPicker()
                Divider()
            }
            
            if customizeLibrary {
                if tabRouterViewModel.pinnedTabsActive {
                    Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                        satellite.present(.customTabValuePreferences)
                    }
                } else if let library {
                    Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                        satellite.present(.customizeLibrary(library, .tabBar))
                    }
                }
            }
            
            Button("preferences", systemImage: "gearshape") {
                satellite.present(.preferences)
            }
            
            Divider()
            
            if !tabRouterViewModel.activeUpdateTasks.isEmpty {
                Text("connection.loading \(tabRouterViewModel.activeUpdateTasks.count)")
            } else if !offlineConnections.isEmpty {
                Text("connection.offline \(offlineConnections.count)")
            }
        } label: {
            if tabRouterViewModel.pinnedTabsActive {
                Label("navigation.library.select", image: "shelfPlayer.fill")
            } else {
                Label("navigation.library.select", systemImage: "books.vertical.fill")
            }
        }
    }
}

#if DEBUG
#Preview {
    CompactLibraryPicker()
        .previewEnvironment()
}
#endif
