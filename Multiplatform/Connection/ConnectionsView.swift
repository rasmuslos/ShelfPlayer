//
//  ConnectionsView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

struct ConnectionManager: View {
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    @State private var loading = false
    @State private var notifyError = false
    
    var body: some View {
        ForEach(connectionStore.connections) { connection in
            NavigationLink(destination: ConnectionManageView(connection: connection)) {
                Text(connection.name)
            }
            .foregroundStyle(connectionStore.offlineConnections.contains(connection.id) ? .red : .primary)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                NavigationLink(destination: ConnectionManageView(connection: connection)) {
                    Label("connection.manage", systemImage: "pencil")
                        .tint(.accentColor)
                }
            }
        }
        .onDelete {
            for index in $0 {
                Task {
                    loading = false
                    
                    await PersistenceManager.shared.remove(connectionID: connectionStore.connections[index].id)
        
                    loading = true
                }
            }
        }
        
        Section {
            Button("connection.add") {
                satellite.present(.addConnection)
            }
            
            Button("connection.removeAll") {
                Task {
                    await PersistenceManager.shared.authorization.reset()
                }
            }
            .foregroundStyle(.red)
        }
        .refreshable {
            connectionStore.update()
        }
        .hapticFeedback(.error, trigger: notifyError)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            ConnectionManager()
        }
    }
    .previewEnvironment()
}
#endif
