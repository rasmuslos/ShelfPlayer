//
//  ConnectionEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import Security
import ShelfPlayback

struct ConnectionAddSheet: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var viewModel = ViewModel()
    
    private var hasValidEndpoint: Bool {
        viewModel.version != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("connection.add.endpoint", text: $viewModel.endpoint)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if let version = viewModel.version {
                        Text("connection.add.versionHint \(version)")
                            .foregroundStyle(.green)
                    } else if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("connection.add.verify") {
                            viewModel.verify()
                        }
                    }
                    
                    OutdatedServerRow(version: viewModel.version)
                } footer: {
                    Text("connection.add.formattingHint")
                }
                .disabled(hasValidEndpoint)
                .onSubmit {
                    viewModel.verify()
                }
                
                #if DEBUG
                CertificateEditor(identity: $viewModel.identity)
                    .disabled(hasValidEndpoint)
                #endif
                
                // No section here, would prevent headers from displaying correctly
                DisclosureGroup("connection.modify.header") {
                    HeaderEditor(headers: $viewModel.headers)
                        .disabled(hasValidEndpoint)
                }
                
                if !viewModel.knownConnections.isEmpty {
                    DisclosureGroup("connection.knownConnections") {
                        ForEach(viewModel.knownConnections) { connection in
                            Button(String("\(connection.host.absoluteString): \(connection.username)")) {
                                viewModel.selectKnownConnection(host: connection.host, username: connection.username)
                            }
                            .disabled(viewModel.isLoading || hasValidEndpoint)
                        }
                    }
                    .animation(.smooth, value: viewModel.knownConnections)
                }
                
                if let strategies = viewModel.strategies, let apiClient = viewModel.apiClient {
                    ConnectionAuthorizer(strategies: strategies, isLoading: $viewModel.isLoading, username: $viewModel.username, apiClient: apiClient, callback: viewModel.storeConnection)
                }
            }
            .navigationTitle("connection.add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .hapticFeedback(.error, trigger: viewModel.notifyError)
            .onChange(of: viewModel.notifyFinished) {
                satellite.dismissSheet()
            }
            .task {
                await viewModel.fetchKnownConnections()
            }
        }
    }
}

@Observable @MainActor
private final class ViewModel: Sendable {
    var endpoint = "https://"
    
    var url: URL?
    var version: String?
    
    #if DEBUG
    var headers = [HeaderShadow]([
        
    ])
    #else
    var headers = [HeaderShadow]()
    #endif
    var identity: SecIdentity?
    
    var username = ""
    var strategies: [AuthorizationStrategy]?
    
    var knownConnections = [PersistenceManager.AuthorizationSubsystem.KnownConnection]()
    
    var isLoading = false
    var notifyError = false
    var notifyFinished = false
    
    var apiClient: APIClient?
    
    func verify() {
        guard !isLoading else {
            return
        }
        
        Task {
            await validateEndpoint()
        }
    }
    
    func validateEndpoint() async {
        while endpoint.last == "/" {
            endpoint.removeLast()
        }
        
        url = URL(string: endpoint)
        
        do {
            guard let url, let apiClient = try? await APIClient(connectionID: "temporary", credentialProvider: AuthorizeAPIClientCredentialProvider(host: url, headers: headers.compactMap(\.materialized), identity: identity)) else {
                notifyError.toggle()
                throw APIClientError.parseError
            }
            
            self.apiClient = apiClient
            
            withAnimation {
                isLoading = true
            }
            
            let status = try await apiClient.status()
            
            guard status.2 else {
                throw ConnectionError.serverIsNotInitialized
            }
            
            withAnimation {
                version = status.0
                strategies = status.1
                
                isLoading = false
            }
        } catch {
            withAnimation {
                version = nil
                isLoading = false
                
                strategies = nil
            }
            
            notifyError.toggle()
        }
    }
    func storeConnection(username: String, accessToken: String, refreshToken: String?) {
        Task {
            let identity = identity
            
            do {
                try await PersistenceManager.shared.authorization.addConnection(host: url!, username: username, headers: headers.compactMap(\.materialized), identity: identity, accessToken: accessToken, refreshToken: refreshToken)
                notifyFinished.toggle()
            } catch {
                notifyError.toggle()
            }
        }
    }
    
    enum ConnectionError: Error {
        case serverIsNotInitialized
        case openIDError
    }
}

extension ViewModel {
    nonisolated func fetchKnownConnections() async {
        let connections = await PersistenceManager.shared.authorization.knownConnections
        
        await MainActor.withAnimation {
            self.knownConnections = connections
        }
    }
    
    func selectKnownConnection(host: URL, username: String) {
        endpoint = ""
        
        url = nil
        version = nil
        
        strategies = nil
        
        endpoint = host.absoluteString
        self.username = username
        
        verify()
    }
}

private final class AuthorizeAPIClientCredentialProvider: APICredentialProvider {
    let host: URL
    let headers: [HTTPHeader]
    let identity: SecIdentity?
    
    init(host: URL, headers: [HTTPHeader], identity: SecIdentity?) {
        self.host = host
        self.headers = headers
        self.identity = identity
    }
    
    public var configuration: (URL, [HTTPHeader]) {
        (host, headers)
    }
    public var accessToken: String? {
        nil
    }
    
    func refreshAccessToken() async throws {
        throw APIClientError.unauthorized
    }
}

extension SecIdentity: @retroactive @unchecked Sendable {}

#if DEBUG
#Preview {
    ConnectionAddSheet()
        .previewEnvironment()
}
#endif
