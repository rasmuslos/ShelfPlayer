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
                    
                    do {
                        try await PersistenceManager.shared.authorization.removeConnection(connectionStore.flat[index].id)
                    } catch {
                        notifyError.toggle()
                    }
                    
                    loading = true
                }
            }
        }
        
        Section {
            NavigationLink("connection.add", destination: ConnectionAddViewWrapper())
            
            Button("connection.reset") {
                Task {
                    do {
                        try await PersistenceManager.shared.authorization.reset()
                    } catch {
                        notifyError.toggle()
                    }
                }
            }
            .foregroundStyle(.red)
        }
        .navigationTitle("connection.manage.multiple")
        .refreshable {
            connectionStore.update()
        }
        .sensoryFeedback(.error, trigger: notifyError)
    }
}

private struct ConnectionAddViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ConnectionAddView() {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ConnectionManager()
        }
    }
    .environment(ConnectionStore())
}
