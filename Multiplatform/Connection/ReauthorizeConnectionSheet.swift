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
    
    var isLoading: Bool {
        viewModel == nil || viewModel?.isLoading == true
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let viewModel {
                    @Bindable var viewModel = viewModel
                    
                    ConnectionAuthorizer(strategies: viewModel.strategies, isLoading: $viewModel.isLoading, username: .constant(viewModel.username), allowUsernameEdit: false, apiClient: viewModel.apiClient) {
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
            .navigationTitle(viewModel?.name ?? connectionID)
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
        .sensoryFeedback(.error, trigger: notifyError)
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
    let username: String
    
    let strategies: [AuthorizationStrategy]
    
    var isLoading = false
    
    init(connectionID: ItemIdentifier.ConnectionID) async throws {
        self.connectionID = connectionID
        apiClient = try await ABSClient[connectionID]
        
        name = try await PersistenceManager.shared.authorization.friendlyName(for: connectionID)
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
