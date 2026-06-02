//
//  ConnectionAuthorizer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.08.25.
//

import SwiftUI
import AuthenticationServices
import OSLog
import ShelfPlayback

struct ConnectionAuthorizer: View {
    private static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "ConnectionAuthorizer")

    typealias Callback = (_ username: String, _ accessToken: String, _ refreshToken: String?) -> Void

    @State private var strategies: [AuthorizationStrategy]
    @Binding private var isLoading: Bool
    @Binding private var username: String

    let allowUsernameEdit: Bool
    let showButton: Bool

    let callback: Callback
    let apiClient: APIClient

    @Binding var authorizeTrigger: Bool

    /// Mirrors the internally selected strategy outward so a host sheet can, e.g.,
    /// disable its own proceed button until a strategy is picked. Write-only from here.
    @Binding private var selectedStrategy: AuthorizationStrategy?

    init(strategies: [AuthorizationStrategy], isLoading: Binding<Bool>, username: Binding<String>, allowUsernameEdit: Bool = true, showButton: Bool = true, authorizeTrigger: Binding<Bool> = .constant(false), selectedStrategy: Binding<AuthorizationStrategy?> = .constant(nil), apiClient: APIClient, callback: @escaping Callback) {
        _strategies = .init(initialValue: strategies)
        _isLoading = isLoading
        _username = username

        self.allowUsernameEdit = allowUsernameEdit
        self.showButton = showButton

        _authorizeTrigger = authorizeTrigger
        _selectedStrategy = selectedStrategy

        self.apiClient = apiClient
        self.callback = callback

        if strategies.count == 1 {
            _strategy = .init(initialValue: strategies.first)
        }
    }

    @State private var strategy: AuthorizationStrategy?

    @State private var password = ""

    @State private var error: Error?
    @State private var notifyError = false

    private let authenticationSessionPresentationContextProvider = AuthenticationSessionPresentationContextProvider()

    var body: some View {
        Group {
            if let strategy {
                Section {
                    switch strategy {
                        case .usernamePassword:
                            TextField("connection.add.username", text: $username)
                                .textContentType(.username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .disabled(!allowUsernameEdit)

                            SecureField("connection.add.password", text: $password)
                                .textContentType(.password)
                        case .openID:
                            // No auto-launch: the browser is started explicitly by the
                            // proceed button (here or in the host sheet) via authorize().
                            Label("connection.add.strategy.openID.label", systemImage: "person.badge.key.fill")
                                .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(strategy.label)
                } footer: {
                    if strategy == .openID {
                        Text("connection.add.strategy.openID.hint")
                    }
                }
                .onSubmit {
                    authorize()
                }
                .disabled(isLoading)
                .onChange(of: authorizeTrigger) {
                    if authorizeTrigger {
                        authorizeTrigger = false
                        authorize()
                    }
                }
                
                if strategies.count > 1 {
                    Section {
                        Button("connection.add.strategy.change") {
                            self.strategy = nil
                        }
                    }
                }

                if showButton {
                    Section {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        } else {
                            Button("connection.add.proceed") {
                                authorize()
                            }
                            .controlSize(.large)
                            .buttonStyle(.glassProminent)
                            .buttonSizing(.flexible)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }
            } else {
                Picker("connection.add.strategy.select", selection: $strategy) {
                    ForEach(strategies) {
                        Text($0.label)
                            .tag($0)
                    }
                }
                .pickerStyle(.inline)
            }

            if let error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }
        }
        .hapticFeedback(.error, trigger: notifyError)
        .onAppear {
            selectedStrategy = strategy
        }
        .onChange(of: strategy) {
            selectedStrategy = strategy
        }
    }

    func authorize() {
        Task {
            do {
                error = nil
                isLoading = true

                Self.logger.info("Begin authorization with strategy \(String(describing: strategy), privacy: .public)")

                switch strategy {
                    case .usernamePassword:
                        try await authorizeLocal()
                    case .openID:
                        try await authorizeOpenID()
                    default:
                        throw APIClientError.parseError
                }
            } catch {
                Self.logger.warning("Authorization failed: \(error, privacy: .public)")

                self.error = error

                notifyError.toggle()
                isLoading = false
            }
        }

        func authorizeLocal() async throws {
            guard !username.isEmpty else {
                notifyError.toggle()
                return
            }

            let (username, accessToken, refreshToken) = try await apiClient.login(username: username, password: password)
            callback(username, accessToken, refreshToken)
        }
        func authorizeOpenID() async throws {
            // Fresh PKCE verifier per attempt so a cancelled or failed flow never reuses a stale one.
            let verifier = String.random(length: 100)

            let session = try await ASWebAuthenticationSession(url: apiClient.openIDLoginURL(verifier: verifier), callback: .customScheme("shelfplayer"), completionHandler: urlCallback)

            session.presentationContextProvider = authenticationSessionPresentationContextProvider
            session.prefersEphemeralWebBrowserSession = true
            session.additionalHeaderFields = try await Dictionary(uniqueKeysWithValues: apiClient.requestHeaders.map { ($0.key, $0.value) })

            session.start()

            func urlCallback(_ url: URL?, _ error: (any Error)?) -> Void {
                Task {
                    guard error == nil, let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems, let code = queryItems.first(where: { $0.name == "code" })?.value, let state = queryItems.first(where: { $0.name == "state" })?.value else {
                        self.isLoading = false
                        self.notifyError.toggle()

                        return
                    }

                    do {
                        let (username, accessToken, refreshToken) = try await apiClient.openIDExchange(code: code, state: state, verifier: verifier)
                        callback(username, accessToken, refreshToken)
                    } catch {
                        Self.logger.warning("OpenID exchange failed: \(error, privacy: .public)")

                        self.error = error

                        self.isLoading = false
                        self.notifyError.toggle()
                    }
                }
            }
        }
    }
}

extension AuthorizationStrategy {
    var label: LocalizedStringKey {
        switch self {
            case .usernamePassword:
                "connection.strategy.usernamePassword"
            case .openID:
                "connection.strategy.oAuth"
        }
    }
}

private final class AuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return ASPresentationAnchor()
        }

        return scene.windows.first { $0.isKeyWindow }
            ?? ASPresentationAnchor(windowScene: scene)
    }
}

#if DEBUG
/// Builds an `APIClient` from a stub credential provider so the authorizer can render
/// without a live connection. The provider never returns a token — previews only exercise layout.
private struct ConnectionAuthorizerPreview: View {
    let strategies: [AuthorizationStrategy]

    @State private var apiClient: APIClient?
    @State private var isLoading = false
    @State private var username = "root"

    var body: some View {
        Form {
            if let apiClient {
                ConnectionAuthorizer(strategies: strategies, isLoading: $isLoading, username: $username, apiClient: apiClient) { _, _, _ in }
            } else {
                ProgressView()
                    .task {
                        apiClient = try? await APIClient(connectionID: "preview", credentialProvider: PreviewCredentialProvider())
                    }
            }
        }
        .formStyle(.grouped)
    }

    private struct PreviewCredentialProvider: APICredentialProvider {
        var configuration: (URL, [HTTPHeader]) {
            (URL(string: "http://localhost:3333")!, [])
        }
        var accessToken: String? { nil }
        func refreshAccessToken() async throws {}
    }
}

#Preview("Strategy picker") {
    ConnectionAuthorizerPreview(strategies: [.usernamePassword, .openID])
}

#Preview("Username & password") {
    ConnectionAuthorizerPreview(strategies: [.usernamePassword])
}

#Preview("OpenID") {
    ConnectionAuthorizerPreview(strategies: [.openID])
}
#endif
