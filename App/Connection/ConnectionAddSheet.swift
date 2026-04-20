//
//  ConnectionAddSheet.swift
//  ShelfPlayer
//

import SwiftUI
import Security
import ShelfPlayback

struct ConnectionAddSheet: View {
    @Environment(Satellite.self) private var satellite

    @State private var viewModel = ViewModel()
    @State private var showAuthorization = false
    @State private var authorizeTrigger = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Header

                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                            .padding(.bottom, 8)

                        Text("connection.add.title")
                            .font(.title2.bold())

                        Text("connection.add.subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                // MARK: Server Address

                Section {
                    TextField("connection.add.endpoint", text: $viewModel.endpoint)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(viewModel.isLoading)

                    NavigationLink("connection.add.customHeaders") {
                        CustomHeaderPage(headers: $viewModel.headers)
                    }
                    .disabled(viewModel.isLoading)
                }

                if let error = viewModel.error {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error.localizedDescription)
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    }
                }

                // MARK: Known Connections

                if !viewModel.knownConnections.isEmpty {
                    Section("connection.knownConnections") {
                        ForEach(viewModel.knownConnections) { connection in
                            Button {
                                viewModel.selectKnownConnection(host: connection.host, username: connection.username)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(connection.host.absoluteString)
                                        .font(.subheadline)
                                    Text(connection.username)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                }

            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.bottom, 8)
                } else {
                    Button("connection.add.connect") {
                        viewModel.verify()
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                    .disabled(viewModel.endpoint.count < 8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .onSubmit {
                viewModel.verify()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .hapticFeedback(.error, trigger: viewModel.notifyError)
            .navigationDestination(isPresented: $showAuthorization) {
                authorizationStep
            }
            .onChange(of: viewModel.version) { _, newValue in
                if newValue != nil {
                    showAuthorization = true
                }
            }
            .onChange(of: showAuthorization) { _, isShowing in
                if !isShowing {
                    viewModel.resetVerification()
                }
            }
            .onChange(of: viewModel.notifyFinished) {
                satellite.dismissSheet()
            }
            .task {
                await viewModel.fetchKnownConnections()
            }
        }
    }

    @ViewBuilder
    private var authorizationStep: some View {
        Form {
            if let version = viewModel.version {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("connection.add.versionHint \(version)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)

                    OutdatedServerRow(version: viewModel.version)
                }
            }

            if let strategies = viewModel.strategies, let apiClient = viewModel.apiClient {
                ConnectionAuthorizer(strategies: strategies, isLoading: $viewModel.isLoading, username: $viewModel.username, showButton: false, authorizeTrigger: $authorizeTrigger, apiClient: apiClient, callback: viewModel.storeConnection)
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.bottom, 8)
            } else {
                Button("connection.add.proceed") {
                    authorizeTrigger = true
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("connection.add.authorize")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@Observable @MainActor
private final class ViewModel: Sendable {
    var endpoint = "https://"

    var url: URL?
    var version: String?

    var headers = [HeaderShadow]()
    var identity: SecIdentity?

    var username = ""
    var strategies: [AuthorizationStrategy]?

    var knownConnections = [PersistenceManager.AuthorizationSubsystem.KnownConnection]()

    var error: Error?

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
        error = nil

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
                self.error = error

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

    func resetVerification() {
        withAnimation {
            version = nil
            strategies = nil
            apiClient = nil
            error = nil
        }
    }

    enum ConnectionError: Error {
        case serverIsNotInitialized
        case openIDError
    }
}

extension ViewModel {
    func fetchKnownConnections() async {
        let connections = await PersistenceManager.shared.authorization.knownConnections

        withAnimation {
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
