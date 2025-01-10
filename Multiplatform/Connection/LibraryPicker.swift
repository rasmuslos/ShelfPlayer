//
//  LibraryPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 09.01.25.
//

import SwiftUI
import RFNotifications
import ShelfPlayerKit

struct LibraryPicker: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    var callback: (() -> Void)? = nil
    
    var body: some View {
        ForEach(connectionStore.flat) { connection in
            if let libraries = connectionStore.libraries[connection.id] {
                Section {
                    ForEach(libraries) { library in
                        Button(library.name, systemImage: image(for: library)) {
                            RFNotification[.changeLibrary].send(library)
                            callback?()
                        }
                    }
                } header: {
                    if connectionStore.connections.count > 1 {
                        Text(verbatim: "\(connection.host.formatted(.url.host())): \(connection.user)")
                    }
                }
            }
        }
        
        if !connectionStore.offlineConnections.isEmpty {
            Button("connection.offline \(connectionStore.offlineConnections.count)", role: .destructive) {
                connectionStore.update()
            }
        }
        
        Button("offline.enable", systemImage: "network.slash") {
            RFNotification[.changeOfflineMode].send(true)
        }
    }
    
    private func image(for library: Library) -> String {
        if library.type == .podcasts {
            "antenna.radiowaves.left.and.right"
        } else {
            "headphones"
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
