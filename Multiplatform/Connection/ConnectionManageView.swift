//
//  ConnectionManageView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.01.25.
//

import SwiftUI
import OSLog
import ShelfPlayerKit

struct ConnectionsManageView: View {
    let logger = Logger(subsystem: "io.rfk.ShelfPlayer", category: "ConnectionManageView")
    
    @State private var connections: [PersistenceManager.AuthorizationSubsystem.Connection] = []
    @State private var notifyError = false
    
    var body: some View {
        List {
            ForEach(connections) { connection in
                NavigationLink(destination: ConnectionManageView(connection: connection)) {
                    Text(String("\(connection.host.absoluteString): \(connection.user)"))
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
        }
        .navigationTitle("connection.manage.multiple")
        .task {
            await fetchConnections()
        }
        .refreshable {
            await fetchConnections()
        }
        .sensoryFeedback(.error, trigger: notifyError)
    }
    
    private func fetchConnections() async {
        connections = Array(await PersistenceManager.shared.authorization.connections.values)
        
        do {
            try await PersistenceManager.shared.authorization.fetchConnections()
            connections = Array(await PersistenceManager.shared.authorization.connections.values)
        } catch {
            logger.error("Error fetching connections: \(error.localizedDescription)")
        }
    }
}

private struct ConnectionManageView: View {
    @Environment(\.dismiss) private var dismiss
    
    let connection: PersistenceManager.AuthorizationSubsystem.Connection
    
    init(connection: PersistenceManager.AuthorizationSubsystem.Connection) {
        self.connection = connection
        
        _headers = .init(initialValue: connection.headers.map { .init(key: $0.key, value: $0.value) })
    }
    
    @State private var loading = false
    @State private var serverVersion: String? = nil
    
    @State private var headers: [HeaderShadow]
    @State private var notifyError = false
    
    var body: some View {
        List {
            Section {
                Text(connection.user)
                Text(connection.host.absoluteString)
            }
            
            HeadersEditSection(headers: $headers)
            
            Section {
                Button("connection.test") {
                    test()
                }
                
                Button("connection.remove") {
                    remove()
                }
                .foregroundStyle(.red)
            }
            .disabled(loading)
        }
        .alert("connection.test.success", isPresented: .init() { serverVersion != nil } set: {
            if !$0 {
                serverVersion = nil
            }
        }) {
            Button("dismiss", role: .cancel) {}
        } message: {
            Text("connection.test.success \(serverVersion ?? "?")")
        }
        .navigationTitle("connection.manage")
        .toolbar {
            if loading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressIndicator()
                }
            }
        }
        .sensoryFeedback(.error, trigger: notifyError)
    }
    
    private func test() {
        Task {
            loading = true
            do {
                serverVersion = try await ABSClient[connection.id].status().serverVersion
            } catch {
                notifyError.toggle()
            }
            loading = false
        }
    }
    private func remove() {
        Task {
            loading = true
            
            do {
                try await PersistenceManager.shared.authorization.removeConnection(connection.id)
                dismiss()
            } catch {
                notifyError.toggle()
                loading = false
            }
            
            loading = false
        }
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
        ConnectionsManageView()
    }
}
