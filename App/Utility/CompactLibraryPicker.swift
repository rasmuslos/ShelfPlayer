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
    @Environment(\.homeScope) private var injectedHomeScope

    @Environment(TabRouterViewModel.self) private var tabRouterViewModel
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite

    var customizeLibrary = false
    /// When set, the "customize" menu entry presents the home-screen
    /// customization sheet for this library type instead of the tab-bar
    /// customization. Intended for use on home panels.
    var customizeHomeLibraryType: LibraryMediaType? = nil

    private var homeCustomizationScope: HomeScope? {
        if let injectedHomeScope { return injectedHomeScope }
        if let library { return .library(library.id) }
        return nil
    }

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

            if let customizeHomeLibraryType, let homeCustomizationScope {
                Button("home.customization.title", systemImage: "slider.horizontal.3") {
                    satellite.present(.customizeHome(homeCustomizationScope, customizeHomeLibraryType))
                }
            } else if customizeLibrary {
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
