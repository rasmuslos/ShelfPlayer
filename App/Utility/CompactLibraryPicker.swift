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

    /// When set, the "customize" menu entry presents the home-screen
    /// customization sheet for this library type instead of the tab-bar
    /// customization. Intended for use on home panels.
    var customizeHomeLibraryType: LibraryMediaType? = nil
    /// When true, the menu operates on the multi-library panel — the
    /// customize-home button targets `HomeScope.multiLibrary` and the
    /// library picker is shown even though a pinned tab is active.
    var isMultiLibraryScope: Bool = false

    private var homeCustomizationScope: HomeScope? {
        if isMultiLibraryScope { return .multiLibrary }
        if let library { return .library(library.id) }
        return nil
    }

    private var showCustomizeHome: Bool {
        homeCustomizationScope != nil && (customizeHomeLibraryType != nil || isMultiLibraryScope)
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
                OfflineMode.shared.forceEnable(reason: "Library picker offline button")
            }

            Divider()

            if !tabRouterViewModel.pinnedTabsActive || isMultiLibraryScope {
                LibraryPicker()
                Divider()
            }

            Menu {
                // Customize home — shown on every home panel: per-library home
                // panels (audiobook / podcast) AND the multi-library Übersicht.
                // The previous `!pinnedTabsActive` gate hid this entry on the
                // Übersicht because `.multiLibrary` reports as a pinned tab,
                // even though customizing the Übersicht is the *primary*
                // customization action there.
                if showCustomizeHome, let homeCustomizationScope {
                    Button(
                        isMultiLibraryScope ? "home.customization.multiLibraryTitle" : "home.customization.title",
                        systemImage: "slider.horizontal.3"
                    ) {
                        satellite.present(.customizeHome(homeCustomizationScope, customizeHomeLibraryType))
                    }
                }

                if !tabRouterViewModel.pinnedTabsActive, let library {
                    Button("preferences.tabs", systemImage: "rectangle.2.swap") {
                        satellite.present(.customizeLibrary(library, .tabBar))
                    }
                }

                if tabRouterViewModel.pinnedTabsActive {
                    Button("preferences.pinnedTabs", systemImage: "rectangle.2.swap") {
                        satellite.present(.customTabValuePreferences)
                    }
                }

                Button("preferences", systemImage: "gearshape") {
                    satellite.present(.preferences)
                }
            } label: {
                Label("preferences", systemImage: "gearshape")
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
