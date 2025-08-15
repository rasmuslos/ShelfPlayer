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
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    @Environment(\.dismiss) private var dismiss
    
    let connection: FriendlyConnection
    
    @State private var isLoading = false
    @State private var status: (String, [AuthorizationStrategy], Bool)?
    
    @State private var isUsingLegacyAuthentication = false
    
    var body: some View {
        List {
            Section {
                Text(connection.username)
                Text(connection.host, format: .url)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(connectionStore.offlineConnections.contains(connection.id) ? .red : .primary)
            }
            
            Section {
                if let status {
                    Text("connection.test.success.message \(status.0)")
                        .foregroundStyle(.green)
                } else {
                    ProgressView()
                }
                
                if isUsingLegacyAuthentication {
                    Text("connection.legacyAuthorization")
                        .foregroundStyle(.orange)
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
                Button {
                    Task {
                        try await PersistenceManager.shared.authorization.scrambleRefreshToken(connectionID: connection.id)
                    }
                } label: {
                    Text(verbatim: "Scramble refresh token")
                }
            }
            #endif
            
            Section {
                Button("action.edit") {
                    satellite.present(.editConnection(connection.id))
                }
                Button("connection.reauthorize") {
                    if let status {
                        satellite.present(.reauthorizeConnection(connection.id, connection.username, status.1))
                    }
                }
                .disabled(status == nil)
                
                Button("connection.remove") {
                    remove()
                }
                .foregroundStyle(.red)
            }
            .disabled(isLoading)
        }
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isUsingLegacyAuthentication = await PersistenceManager.shared.authorization.isUsingLegacyAuthentication(for: connection.id)
        }
        .task {
            status = try? await ABSClient[connection.id].status()
        }
    }
    
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
        .previewEnvironment()
}
#endif
