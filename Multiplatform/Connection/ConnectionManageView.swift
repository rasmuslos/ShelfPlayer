//
//  ConnectionManageView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 02.01.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

struct ConnectionManageView: View {
    @Environment(\.dismiss) private var dismiss
    
    let connection: FriendlyConnection
    
    @State private var isLoading = false
    @State private var serverVersion: String?
    
    var hasUnsavedChanges: Bool {
        true
    }
    
    var body: some View {
        List {
            Section {
                Text(connection.username)
                Text(connection.host, format: .url)
                    .font(.caption)
                    .fontDesign(.monospaced)
            }
            
            Section {
                if let serverVersion {
                    Text("connection.add.versionHint \(serverVersion)")
                        .foregroundStyle(.green)
                } else {
                    ProgressView()
                        .task {
                            serverVersion = try? await ABSClient[connection.id].status().serverVersion
                        }
                }
            }
            
            #if DEBUG
            Section {
                Button {
                    Task {
                        try await PersistenceManager.shared.authorization.scrambleAccessToken(connectionID: connection.id)
                    }
                } label: {
                    Text(verbatim: "Scramble access token")
                }
            }
            #endif
            
            Section {
                Button("action.edit") {
                    
                }
                Button("connection.remove") {
                    remove()
                }
                .foregroundStyle(.red)
            }
            .disabled(isLoading)
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /*
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
     */
    private func remove() {
        Task {
            isLoading = true
            
            await PersistenceManager.shared.remove(connectionID: connection.id)
            dismiss()
            
            isLoading = false
        }
    }
}

#if DEBUG
#Preview {
    ConnectionManageView(connection: .fixture)
}
#endif
