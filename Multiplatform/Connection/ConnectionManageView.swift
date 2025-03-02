//
//  ConnectionManageView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.01.25.
//

import SwiftUI
import OSLog
import ShelfPlayerKit

struct ConnectionManageView: View {
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
    
    var hasUnsavedChanges: Bool {
        connection.headers != headers.compactMap(\.materialized)
    }
    
    var body: some View {
        List {
            Section {
                Text(connection.user)
                Text(connection.host.absoluteString)
            }
            
            HeaderEditor(headers: $headers)
            
            Section {
                Button("connection.test") {
                    test()
                }
                .disabled(hasUnsavedChanges)
                
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
                ToolbarItem(placement: .topBarTrailing) {
                    if loading {
                        ProgressIndicator()
                    } else if hasUnsavedChanges {
                        Button("connection.save") {
                            update()
                        }
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
    
    private func update() {
        Task {
            loading = true
            
            do {
                try await PersistenceManager.shared.authorization.updateConnection(connection.id, headers: headers.compactMap(\.materialized))
            } catch {
                notifyError.toggle()
                loading = false
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
