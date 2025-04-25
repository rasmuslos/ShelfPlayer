//
//  LibraryPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct LibraryPicker: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    var callback: (() -> Void)? = nil
    
    var body: some View {
        ForEach(connectionStore.flat) { connection in
            if let libraries = connectionStore.libraries[connection.id] {
                Section(connection.friendlyName) {
                    ForEach(libraries) { library in
                        Button(library.name, systemImage: library.icon) {
                            RFNotification[.changeLibrary].send(library)
                            callback?()
                        }
                    }
                }
            }
        }
        
        if connectionStore.libraries.count + connectionStore.offlineConnections.count < connectionStore.connections.count {
            Text("connection.loading \(connectionStore.connections.count - (connectionStore.libraries.count + connectionStore.offlineConnections.count))")
        } else if !connectionStore.offlineConnections.isEmpty {
            Button("connection.offline \(connectionStore.offlineConnections.count)", role: .destructive) {
                connectionStore.update()
            }
        }
        
        Button("navigation.offline.enable", systemImage: "network.slash") {
            RFNotification[.changeOfflineMode].send(true)
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

extension RFNotification.Notification {
    static var changeLibrary: Notification<Library> { .init("io.rfk.shelfPlayer.changeLibrary") }
    static var changeOfflineMode: Notification<Bool> { .init("io.rfk.shelfPlayer.changeOfflineMode") }
}

#Preview {
    Menu {
        LibraryPicker()
    } label: {
        Text(verbatim: "LibraryPicker")
    }
    .environment(ConnectionStore())
}
