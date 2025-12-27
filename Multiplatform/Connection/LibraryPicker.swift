//
//  LibraryPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.01.25.
//

import SwiftUI
import ShelfPlayback

struct LibraryPicker: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    @Default(.customTabsActive) private var customTabsActive
    
    var callback: (() -> Void)? = nil
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        if isCompact {
            Toggle(isOn: .init { customTabsActive } set: { _ in
                RFNotification[.toggleCustomTabsActive].send()

            }) {
                Label("panel.home", image: "shelfPlayer.fill")
            }
        }
        
        if !(isCompact && customTabsActive) {
            ForEach(connectionStore.connections) { connection in
                if let libraries = connectionStore.libraries[connection.id] {
                    Section(connection.name) {
                        ForEach(libraries) { library in
                            Toggle(library.name, systemImage: library.icon, isOn: .init { satellite.tabValue?.library == library } set: { _ in
                                RFNotification[.changeLibrary].send(payload: library)
                                callback?()
                            })
                        }
                    }
                }
            }
        }
        
        Divider()
        
        Button("preferences", systemImage: "gearshape") {
            satellite.present(.preferences)
        }
        
        Button("navigation.offline.enable", systemImage: "network.slash") {
            OfflineMode.shared.setEnabled(true)
        }
        
        if connectionStore.libraries.count + connectionStore.offlineConnections.count < connectionStore.connections.count {
            Text("connection.loading \(connectionStore.connections.count - (connectionStore.libraries.count + connectionStore.offlineConnections.count))")
        } else if !connectionStore.offlineConnections.isEmpty {
            Button("connection.offline \(connectionStore.offlineConnections.count)", role: .destructive) {
                connectionStore.update()
            }
        }
    }
}
struct LibraryPickerMenu: View {
    @Default(.customTabsActive) private var customTabsActive
    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library
    
    var customizeLibrary = false
    
    var body: some View {
        Menu {
            LibraryPicker()
            
            Divider()
            
            if !customTabsActive && customizeLibrary, let library {
                Button("action.customize", systemImage: "list.bullet.badge.ellipsis") {
                    satellite.present(.customizeLibrary(library, .tabBar))
                }
            }
        } label: {
            if customTabsActive {
                Label("navigation.library.select", image: "shelfPlayer.fill")
            } else {
                Label("navigation.library.select", systemImage: "books.vertical.fill")
            }
        }
    }
}

extension Library {
    var icon: String {
        switch type {
        case .audiobooks:
            "headphones"
        case .podcasts:
            "antenna.radiowaves.left.and.right"
        }
    }
}

#if DEBUG
#Preview {
    Menu {
        LibraryPicker()
    } label: {
        Text(verbatim: "LibraryPicker")
    }
    .previewEnvironment()
}
#endif
