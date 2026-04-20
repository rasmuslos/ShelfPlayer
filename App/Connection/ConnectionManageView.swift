//
//  ConnectionManageView.swift
//  ShelfPlayer
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
    @State private var libraries: [Library]?
    @State private var libraryCounts: [String: Int] = [:]

    @State private var isUsingLegacyAuthentication = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                        .padding(.bottom, 8)

                    Text(connection.username)
                        .font(.title2.bold())

                    Text(connection.host, format: .url)
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .foregroundStyle(connectionStore.offlineConnections.contains(connection.id) ? .red : .secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                if let status {
                    Text("connection.test.success.message \(status.0)")
                        .foregroundStyle(.green)
                } else {
                    ProgressView()
                }

                OutdatedServerRow(version: status?.0)

                if isUsingLegacyAuthentication {
                    Text("connection.legacyAuthorization")
                        .foregroundStyle(.orange)
                }
            }

            if let libraries {
                Section("connection.manage.libraries") {
                    if libraries.isEmpty {
                        Text("connection.manage.libraries.empty")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(libraries) { library in
                            LabeledContent {
                                if let count = libraryCounts[library.id.libraryID] {
                                    Text(count, format: .number)
                                } else {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            } label: {
                                Label(library.name, systemImage: library.id.type == .audiobooks ? "books.vertical" : "antenna.radiowaves.left.and.right")
                            }
                        }
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
                Button {
                    Task {
                        try await PersistenceManager.shared.authorization.scrambleRefreshToken(connectionID: connection.id)
                    }
                } label: {
                    Text(verbatim: "Scramble refresh token")
                }
            }
            #endif
        }
        .formStyle(.grouped)
        .navigationTitle("connection.manage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("action.edit") {
                        satellite.present(.editConnection(connection.id))
                    }
                    Button("connection.reauthorize") {
                        satellite.present(.reauthorizeConnection(connection.id))
                    }
                    .disabled(status == nil)

                    Divider()

                    Button("connection.remove", role: .destructive) {
                        Self.remove(connectionID: connection.id, isLoading: $isLoading) {
                            dismiss()
                        }
                    }
                } label: {
                    Label("connection.manage", systemImage: "ellipsis.circle")
                }
                .disabled(isLoading)
            }
        }
        .task {
            isUsingLegacyAuthentication = await PersistenceManager.shared.authorization.isUsingLegacyAuthentication(for: connection.id)
        }
        .task {
            status = try? await ABSClient[connection.id].status()
        }
        .task {
            guard let fetched = try? await ABSClient[connection.id].libraries() else {
                return
            }

            withAnimation {
                libraries = fetched
            }

            await withTaskGroup(of: (String, Int)?.self) { group in
                for library in fetched {
                    group.addTask {
                        let client = try? await ABSClient[connection.id]

                        switch library.id.type {
                        case .audiobooks:
                            guard let (_, total) = try? await client?.audiobooks(from: library.id.libraryID, filter: .all, sortOrder: .added, ascending: false, limit: 0, page: 0) else {
                                return nil
                            }
                            return (library.id.libraryID, total)
                        case .podcasts:
                            guard let (_, total) = try? await client?.podcasts(from: library.id.libraryID, sortOrder: .addedAt, ascending: false, limit: 0, page: 0) else {
                                return nil
                            }
                            return (library.id.libraryID, total)
                        }
                    }
                }

                for await result in group {
                    if let (libraryID, total) = result {
                        withAnimation {
                            libraryCounts[libraryID] = total
                        }
                    }
                }
            }
        }
    }

    static func remove(connectionID: ItemIdentifier.ConnectionID, isLoading: Binding<Bool>, callback: @escaping () -> Void) {
        Task {
            isLoading.wrappedValue = true

            await PersistenceManager.shared.remove(connectionID: connectionID)
            callback()

            isLoading.wrappedValue = false
        }
    }
}

#if DEBUG
#Preview {
    ConnectionManageView(connection: .fixture)
        .previewEnvironment()
}
#endif
