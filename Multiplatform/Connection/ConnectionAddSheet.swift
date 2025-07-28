//
//  ConnectionEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import Security
import AuthenticationServices
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
                            viewModel.proceed()
                        }
                    }
                } footer: {
                    Text("connection.add.formattingHint")
                }
                .disabled(hasValidEndpoint)
                
                CertificateEditor(identity: $viewModel.identity)
                    .disabled(hasValidEndpoint)
                
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
                
                if !viewModel.strategies.isEmpty {
                    if let strategy = viewModel.strategy {
                        if viewModel.strategies.count > 1 {
                            Section {
                                Button("connection.add.strategy.change") {
                                    viewModel.strategy = nil
                                }
                            }
                        }
                        
                        Section {
                            switch strategy {
                                case .usernamePassword:
                                    TextField("connection.add.username", text: $viewModel.username)
                                        .textContentType(.username)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                    
                                    SecureField("connection.add.password", text: $viewModel.password)
                                        .textContentType(.password)
                                    
                                    Button("connection.add.proceed") {
                                        viewModel.proceed()
                                    }
                                    .disabled(viewModel.isLoading)
                                case .openID:
                                    Button("action.retry") {
                                        viewModel.proceed()
                                    }
                                    .disabled(viewModel.isLoading)
                                    .onAppear {
                                        viewModel.proceed()
                                    }
                            }
                        } header: {
                            Text(strategy.label)
                        } footer: {
                            if strategy == .openID {
                                Text("connection.add.strategy.openID.hint")
                            }
                        }
                    } else {
                        Picker("connection.add.strategy.select", selection: $viewModel.strategy) {
                            ForEach(viewModel.strategies) {
                                Text($0.label)
                                    .tag($0)
                            }
                        }
                        .pickerStyle(.inline)
                    }
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
                    } else {
                        Button("connection.add.proceed") {
                            viewModel.proceed()
                        }
                    }
                }
            }
            .sensoryFeedback(.error, trigger: viewModel.notifyError)
            .onSubmit {
                viewModel.proceed()
            }
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
    
    var username = ""
    var password = ""
    
    var verifier: String!
    
    var headers = [HeaderShadow]()
    var identity: SecIdentity?
    
    var strategy: AuthorizationStrategy?
    var strategies = [AuthorizationStrategy]()
    
    var knownConnections = [PersistenceManager.AuthorizationSubsystem.KnownConnection]()
    
    var isLoading = false
    var notifyError = false
    var notifyFinished = false
    
    let authenticationSessionPresentationContextProvider = AuthenticationSessionPresentationContextProvider()
    
    var apiClient: APIClient {
        get async throws {
            if let url {
                return try await APIClient(connectionID: "temporary", credentialProvider: AuthorizeAPIClientCredentialProvider(host: url, headers: headers.compactMap(\.materialized), identity: identity))
            } else {
                throw APIClientError.notFound
            }
        }
    }
}

// MARK: General

extension ViewModel {
    func proceed() {
        guard !isLoading else {
            return
        }
        
        // These API calls will block the main actor
        Task {
            if let strategy, let client = try? await apiClient {
               await authorize(strategy: strategy, client: client)
            } else {
                await validateEndpoint()
            }
        }
    }
    
    func validateEndpoint() async {
        while endpoint.last == "/" {
            endpoint.removeLast()
        }
        
        url = URL(string: endpoint)
        
        guard let client = try? await apiClient else {
            notifyError.toggle()
            return
        }
        
        do {
            withAnimation {
                isLoading = true
            }
            
            let status = try await client.status()
            
            guard status.isInit else {
                throw ConnectionError.serverIsNotInitialized
            }
            
            withAnimation {
                version = status.serverVersion
                isLoading = false
                
                strategies = status.authMethods.compactMap {
                    switch $0 {
                        case "local":
                                .usernamePassword
                        case "openid":
                                .openID
                        default:
                            nil
                    }
                }
                
                if strategies.contains(.openID) {
                    verifier = String.random(length: 100)
                }
                
                if strategies.count == 1 {
                    strategy = strategies.first
                }
            }
        } catch {
            withAnimation {
                version = nil
                isLoading = false
                
                strategies = []
                strategy = nil
            }
            
            notifyError.toggle()
        }
    }
    
    enum ConnectionError: Error {
        case serverIsNotInitialized
        case openIDError
    }
    enum AuthorizationStrategy: Int, Identifiable {
        case usernamePassword
        case openID
        
        var id: Int {
            rawValue
        }
        
        var label: LocalizedStringKey {
            switch self {
                case .usernamePassword:
                    "connection.strategy.usernamePassword"
                case .openID:
                    "connection.strategy.oAuth"
            }
        }
    }
}

// MARK: Authorize

extension ViewModel {
    func authorize(strategy: AuthorizationStrategy, client: APIClient) async {
        do {
            isLoading = true
            
            switch strategy {
                case .usernamePassword:
                    try await authorizeLocal()
                case .openID:
                    try await authorizeOpenID()
            }
        } catch {
            notifyError.toggle()
            isLoading = false
        }
        
        // qq
        func authorizeLocal() async throws {
            guard !username.isEmpty else {
                notifyError.toggle()
                return
            }
            
            let (username, accessToken, refreshToken) = try await client.login(username: username, password: password)
            let identity = identity
            
            try await PersistenceManager.shared.authorization.addConnection(host: url!, username: username, headers: headers.compactMap(\.materialized), identity: identity, accessToken: accessToken, refreshToken: refreshToken)
            
            notifyFinished.toggle()
        }
        func authorizeOpenID() async throws {
            // TODO: a
            let session = try await ASWebAuthenticationSession(url: .temporaryDirectory, callback: .customScheme("shelfplayer")) {
                // client.openIDLoginURL(verifier: verifier), callback: .customScheme("shelfplayer")) {
                guard $1 == nil,
                      let callback = $0,
                      let components = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems,
                      let code = queryItems.first(where: { $0.name == "code" })?.value,
                      let state = queryItems.first(where: { $0.name == "state" })?.value else {
                    Task { @MainActor in
                        self.isLoading = false
                        self.notifyError.toggle()
                    }
                    
                    return
                }
                
                Task { @MainActor in
                    do {
                        let (username, token) = ("", "") // try await client.openIDExchange(code: code, state: state, verifier: self.verifier)
                                                         // try await PersistenceManager.shared.authorization.addConnection(.init(host: url, user: username, token: token, headers: headers))
                        
                        self.notifyFinished.toggle()
                    } catch {
                        self.isLoading = false
                        self.notifyError.toggle()
                    }
                }
            }
            
            session.presentationContextProvider = authenticationSessionPresentationContextProvider
            session.prefersEphemeralWebBrowserSession = true
            session.additionalHeaderFields = Dictionary(uniqueKeysWithValues: headers.map { ($0.key, $0.value) })
            
            session.start()
        }
    }
}

// MARK: Known connections

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
        
        self.username = ""
        password = ""
        
        strategy = nil
        strategies = []
        
        endpoint = host.absoluteString
        
        proceed()
        
        self.username = username
    }
}

private final class AuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
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
    
    public var configuration: (URL, [HTTPHeader], SecIdentity?) {
        (host, headers, identity)
    }
    public func requestSessionToken(refresh: Bool) async throws -> String? {
        nil
    }
}

extension SecIdentity: @retroactive @unchecked Sendable {}

#if DEBUG
#Preview {
    ConnectionAddSheet()
        .previewEnvironment()
}
#endif
