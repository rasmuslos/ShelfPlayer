//
//  ReauthorizeConnectionSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 15.08.25.
//

import SwiftUI
import ShelfPlayback

struct ReauthorizeConnectionSheet: View {
    @Environment(Satellite.self) private var satellite

    let connectionID: ItemIdentifier.ConnectionID

    @State private var viewModel: ViewModel?
    @State private var notifyError = false
    @State private var authorizeTrigger = false

    var isLoading: Bool {
        viewModel == nil || viewModel?.isLoading == true
    }

    var body: some View {
        NavigationStack {
            Form {
                if let viewModel {
                    @Bindable var viewModel = viewModel

                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.blue)
                                .padding(.bottom, 8)

                            Text("connection.reauthorize")
                                .font(.title2.bold())

                            Text(viewModel.host.absoluteString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    ConnectionAuthorizer(strategies: viewModel.strategies, isLoading: $viewModel.isLoading, username: .constant(viewModel.username), allowUsernameEdit: false, showButton: false, authorizeTrigger: $authorizeTrigger, apiClient: viewModel.apiClient) {
                        guard viewModel.username == $0 else {
                            notifyError.toggle()
                            return
                        }

                        let accessToken = $1
                        let refreshToken = $2

                        Task {
                            do {
                                try await PersistenceManager.shared.authorization.updateConnection(connectionID, accessToken: accessToken, refreshToken: refreshToken)
                                dismiss()
                            } catch {
                                notifyError.toggle()
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            Task {
                                do {
                                    viewModel = try await .init(connectionID: connectionID)
                                } catch {
                                    notifyError.toggle()
                                }
                            }
                        }
                }
            }
            .formStyle(.grouped)
            .safeAreaInset(edge: .bottom) {
                if viewModel != nil {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 4)
                        } else {
                            Button("connection.remove", role: .destructive) {
                                ConnectionManageView.remove(connectionID: connectionID, isLoading: .init { viewModel?.isLoading ?? false } set: { viewModel?.isLoading = $0 }) {
                                    dismiss()
                                }
                            }
                            .controlSize(.large)
                            .buttonStyle(.bordered)
                            .buttonSizing(.flexible)
                            .foregroundStyle(.red)
                            Button("connection.add.proceed") {
                                authorizeTrigger = true
                            }
                            .controlSize(.large)
                            .buttonStyle(.borderedProminent)
                            .buttonSizing(.flexible)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("connection.reauthorize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .hapticFeedback(.error, trigger: notifyError)
    }

    private func dismiss() {
        satellite.dismissSheet(id: "reauthorizeConnection-\(connectionID)")
    }
}

@Observable @MainActor
private final class ViewModel {
    let connectionID: ItemIdentifier.ConnectionID
    let apiClient: APIClient

    let name: String
    let host: URL
    let username: String

    let strategies: [AuthorizationStrategy]

    var isLoading = false

    init(connectionID: ItemIdentifier.ConnectionID) async throws {
        self.connectionID = connectionID
        apiClient = try await ABSClient[connectionID]

        name = try await PersistenceManager.shared.authorization.friendlyName(for: connectionID)
        host = try await PersistenceManager.shared.authorization.host(for: connectionID)
        username = try await PersistenceManager.shared.authorization.username(for: connectionID)

        (_, strategies, _) = try await apiClient.status()
    }
}

#if DEBUG
#Preview {
    ReauthorizeConnectionSheet(connectionID: "fixture")
        .previewEnvironment()
}
#endif
