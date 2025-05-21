//
//  ConnectionEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import AuthenticationServices
import ShelfPlayerKit

struct ConnectionAddView: View {
    let finished: () -> Void
    
    @State private var viewModel = ViewModel()
    
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
                    } else if viewModel.loading {
                        ProgressView()
                    } else {
                        Button("connection.add.verify") {
                            viewModel.proceed()
                        }
                    }
                } footer: {
                    Text("connection.add.formattingHint")
                }
                .disabled(viewModel.version != nil || viewModel.endpoint.isEmpty)
                
                // No section here, would prevent headers from displaying correctly
                DisclosureGroup("connection.modify.header") {
                    HeaderEditor(headers: $viewModel.headers)
                }
                
                if !viewModel.knownConnections.isEmpty {
                    DisclosureGroup("connection.knownConnections") {
                        ForEach(viewModel.knownConnections) { connection in
                            Button(String("\(connection.host.absoluteString): \(connection.username)")) {
                                viewModel.selectKnownConnection(host: connection.host, username: connection.username)
                            }
                            .disabled(viewModel.loading)
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
                                .disabled(viewModel.loading)
                            case .openID:
                                Button("action.retry") {
                                    viewModel.proceed()
                                }
                                .disabled(viewModel.loading)
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
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.loading {
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
                didFinish()
            }
            .task {
                await viewModel.fetchKnownConnections()
            }
        }
    }
    
    private func didFinish() {
        viewModel = .init()
        finished()
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
    
    var strategy: AuthorizationStrategy?
    var strategies = [AuthorizationStrategy]()
    
    var knownConnections = [PersistenceManager.AuthorizationSubsystem.KnownConnection]()
    
    var loading = false
    var notifyError = false
    var notifyFinished = false
    
    let authenticationSessionPresentationContextProvider = AuthenticationSessionPresentationContextProvider()
    
    func proceed() {
        guard !loading else {
            return
        }
        
        // These API calls will block the main actor
        Task {
            if let strategy, let url {
                do {
                    loading = true
                    
                    let headers = headers.compactMap(\.materialized)
                    let client = APIClient(connectionID: "temporary", host: url, headers: headers)
                    
                    switch strategy {
                    case .usernamePassword:
                        guard !username.isEmpty else {
                            notifyError.toggle()
                            return
                        }
                        
                        let token = try await client.login(username: username, password: password)
                        
                        try await PersistenceManager.shared.authorization.addConnection(.init(host: url, user: username, token: token, headers: headers))
                        
                        notifyFinished.toggle()
                    case .openID:
                        // TODO:
                        let session = try await ASWebAuthenticationSession(url: client.openIDLoginURL(verifier: verifier), callback: .customScheme("shelfplayer")) {
                            guard $1 == nil,
                                  let callback = $0,
                                  let components = URLComponents(url: callback, resolvingAgainstBaseURL: false),
                                  let queryItems = components.queryItems,
                                  let code = queryItems.first(where: { $0.name == "code" })?.value,
                                  let state = queryItems.first(where: { $0.name == "state" })?.value else {
                                Task { @MainActor in
                                    self.loading = false
                                    self.notifyError.toggle()
                                }
                                
                                return
                            }
                            
                            Task { @MainActor in
                                do {
                                    let (username, token) = try await client.openIDExchange(code: code, state: state, verifier: self.verifier)
                                    try await PersistenceManager.shared.authorization.addConnection(.init(host: url, user: username, token: token, headers: headers))
                                    
                                    self.notifyFinished.toggle()
                                } catch {
                                    self.loading = false
                                    self.notifyError.toggle()
                                }
                            }
                        }
                        
                        session.presentationContextProvider = authenticationSessionPresentationContextProvider
                        session.prefersEphemeralWebBrowserSession = true
                        session.additionalHeaderFields = Dictionary(uniqueKeysWithValues: headers.map { ($0.key, $0.value) })
                        
                        session.start()
                    }
                } catch {
                    notifyError.toggle()
                    loading = false
                }
            } else {
                await validateEndpoint()
            }
        }
    }
    
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
    
    func validateEndpoint() async {
        while endpoint.last == "/" {
            endpoint.removeLast()
        }
        
        url = URL(string: endpoint)
        
        guard let url else {
            notifyError.toggle()
            return
        }
        
        let client = APIClient(connectionID: "temporary", host: url, headers: headers.compactMap(\.materialized))
        
        #if DEBUG
        // client.verbose = true
        #endif
        
        do {
            withAnimation {
                loading = true
            }
            
            let status = try await client.status()
            
            guard status.isInit else {
                throw ConnectionError.serverIsNotInitialized
            }
            
            withAnimation {
                version = status.serverVersion
                loading = false
                
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
                loading = false
                
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

private final class AuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

#Preview {
    ConnectionAddView() {}
}
