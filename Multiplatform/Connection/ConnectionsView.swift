//
//  ConnectionsView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 07.01.25.
//

import SwiftUI
import OSLog
import ShelfPlayerKit

struct ConnectionManager: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    @State private var loading = false
    @State private var notifyError = false
    
    var body: some View {
        ForEach(connectionStore.flat) { connection in
            NavigationLink(destination: ConnectionManageView(connection: connection)) {
                Text(String("\(connection.host.absoluteString): \(connection.user)"))
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
                    
                    await PersistenceManager.shared.remove(connectionID: connectionStore.flat[index].id)
        
                    loading = true
                }
            }
        }
        
        Section {
            NavigationLink("connection.add", destination: ConnectionAddView() {})
            
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
        .sensoryFeedback(.error, trigger: notifyError)
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
