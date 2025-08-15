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
    let username: String
    let strategies: [AuthorizationStrategy]
    
    @State private var isLoading = false
    @State private var apiClient: APIClient?
    
    @State private var notifyError = false
    
    var body: some View {
        NavigationStack {
            List {
                if let apiClient {
                    ConnectionAuthorizer(strategies: strategies, isLoading: $isLoading, username: .constant(username), allowUsernameEdit: false, apiClient: apiClient) {
                        guard username == $0 else {
                            notifyError.toggle()
                            return
                        }
                        
                        let accessToken = $1
                        let refreshToken = $2
                        
                        Task {
                            do {
                                try await PersistenceManager.shared.authorization.updateConnection(connectionID, accessToken: accessToken, refreshToken: refreshToken)
                                satellite.dismissSheet()
                            } catch {
                                notifyError.toggle()
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .task {
                            apiClient = try? await ABSClient[connectionID]
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .sensoryFeedback(.error, trigger: notifyError)
    }
}

#if DEBUG
#Preview {
    ReauthorizeConnectionSheet(connectionID: "fixture", username: "Adam Smith", strategies: [.usernamePassword, .openID])
        .previewEnvironment()
}
#endif
