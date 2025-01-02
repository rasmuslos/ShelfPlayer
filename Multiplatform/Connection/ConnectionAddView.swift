//
//  ConnectionEditView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import RFNetwork
import ShelfPlayerKit

struct ConnectionAddView: View {
    let finished: () -> Void
    
    @State private var viewModel = ViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("connection.endpoint", text: $viewModel.endpoint)
                    
                    if let version = viewModel.version {
                        Text("connection.versionHint \(version)")
                            .foregroundStyle(.green)
                    } else if viewModel.loading {
                        ProgressIndicator()
                    } else {
                        Button("connection.verify") {
                            viewModel.proceed()
                        }
                    }
                } footer: {
                    Text("connection.formattingHint")
                }
                .disabled(viewModel.version != nil || viewModel.endpoint.isEmpty)
                
                Section {
                    DisclosureGroup("connection.headers") {
                        HeadersEditSection(headers: $viewModel.headers)
                    }
                    
                    if !viewModel.knownServers.isEmpty {
                        DisclosureGroup("connection.knownServers") {
                            ForEach(viewModel.knownServers) { server in
                                Button(String("\(server.host.absoluteString): \(server.username)")) {
                                    viewModel.selectKnownServer(host: server.host, username: server.username)
                                }
                                .disabled(viewModel.loading)
                            }
                        }
                        .animation(.smooth, value: viewModel.knownServers)
                    }
                }
                
                if !viewModel.strategies.isEmpty {
                    if let strategy = viewModel.strategy {
                        if viewModel.strategies.count > 1 {
                            Section {
                                Button("configuration.strategy.change") {
                                    viewModel.strategy = nil
                                }
                            }
                        }
                        
                        Section(strategy.label) {
                            switch strategy {
                            case .usernamePassword:
                                TextField("Name", text: $viewModel.username)
                                    .textContentType(.username)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                                
                                if viewModel.loading {
                                    ProgressIndicator()
                                } else {
                                    Button("connection.login") {
                                        viewModel.proceed()
                                    }
                                }
                            case .openID:
                                ProgressIndicator()
                            }
                        }
                    } else {
                        Picker("connection.strategy", selection: $viewModel.strategy) {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.loading {
                        ProgressIndicator()
                    } else {
                        Button("proceed") {
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
                await viewModel.fetchKnownServers()
            }
        }
    }
    
    private func didFinish() {
        viewModel = .init()
        finished()
    }
}

struct ConnectionAddSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ConnectionAddView() {
                    isPresented = false
                }
            }
    }
}

@Observable @MainActor
private final class ViewModel: Sendable {
    var endpoint = "https://audiobooks.dev"
    
    var url: URL?
    var version: String?
    
    var username = ""
    var password = ""
    
    var headers = [HeaderShadow]()
    
    var strategy: AuthorizationStrategy?
    var strategies = [AuthorizationStrategy]()
    
    var knownServers = [PersistenceManager.AuthorizationSubsystem.KnownServer]()
    
    var loading = false
    var notifyError = false
    var notifyFinished = false
    
    func proceed() {
        guard !loading else {
            return
        }
        
        // These API calls will block the main actor
        Task {
            if let strategy, let url {
                do {
                    switch strategy {
                    case .usernamePassword:
                        guard !username.isEmpty else {
                            notifyError.toggle()
                            return
                        }
                        
                        loading = true
                        
                        let headers = headers.compactMap(\.materialized)
                        let client = APIClient(serverID: "temporary", host: url, headers: headers)
                        
                        let token = try await client.login(username: username, password: password)
                        
                        try await PersistenceManager.shared.authorization.addServer(.init(host: url, user: username, token: token, headers: headers))
                        
                        notifyFinished.toggle()
                    case .openID:
                        // TODO:
                        ""
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
    
    nonisolated func fetchKnownServers() async {
        let servers = await PersistenceManager.shared.authorization.knownServers
        
        await MainActor.run {
            self.knownServers = servers
        }
    }
    
    func selectKnownServer(host: URL, username: String) {
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
        url = URL(string: endpoint)
        
        guard let url else {
            notifyError.toggle()
            return
        }
        
        let client = APIClient(serverID: "temporary", host: url, headers: headers.compactMap(\.materialized))
        
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

@Observable @MainActor
final class HeaderShadow {
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
    
    var isValid: Bool {
        !key.isEmpty && !value.isEmpty
    }
    var materialized: HTTPHeader? {
        guard isValid else {
            return nil
        }
        
        return .init(key: key, value: value)
    }
}

#Preview {
    ConnectionAddView() {
        
    }
}
