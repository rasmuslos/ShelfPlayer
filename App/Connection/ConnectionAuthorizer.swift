//
//  ConnectionAuthorizer.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.08.25.
//

import SwiftUI
import AuthenticationServices
import ShelfPlayback

struct ConnectionAuthorizer: View {
    typealias Callback = (_ username: String, _ accessToken: String, _ refreshToken: String?) -> Void

    @State private var strategies: [AuthorizationStrategy]
    @Binding private var isLoading: Bool
    @Binding private var username: String

    let allowUsernameEdit: Bool
    let showButton: Bool

    let callback: Callback
    let apiClient: APIClient

    @Binding var authorizeTrigger: Bool

    init(strategies: [AuthorizationStrategy], isLoading: Binding<Bool>, username: Binding<String>, allowUsernameEdit: Bool = true, showButton: Bool = true, authorizeTrigger: Binding<Bool> = .constant(false), apiClient: APIClient, callback: @escaping Callback) {
        _strategies = .init(initialValue: strategies)
        _isLoading = isLoading
        _username = username

        self.allowUsernameEdit = allowUsernameEdit
        self.showButton = showButton

        _authorizeTrigger = authorizeTrigger

        self.apiClient = apiClient
        self.callback = callback

        if strategies.count == 1 {
            _strategy = .init(initialValue: strategies.first)
        }
    }

    @State private var strategy: AuthorizationStrategy?

    @State private var password = ""
    @State private var verifier = String.random(length: 100)

    @State private var error: Error?
    @State private var notifyError = false

    private let authenticationSessionPresentationContextProvider = AuthenticationSessionPresentationContextProvider()

    var body: some View {
        if let strategy {
            if strategies.count > 1 {
                Section {
                    Button("connection.add.strategy.change") {
                        self.strategy = nil
                    }
                }
            }

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
                        EmptyView()
                            .onAppear {
                                authorize()
                            }
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

            if showButton && strategy == .usernamePassword {
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
                        .buttonStyle(.borderedProminent)
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

    func authorize() {
        Task {
            do {
                error = nil
                isLoading = true

                switch strategy {
                    case .usernamePassword:
                        try await authorizeLocal()
                    case .openID:
                        try await authorizeOpenID()
                    default:
                        throw APIClientError.parseError
                }
            } catch {
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
            return ASPresentationAnchor(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
        }

        return scene.windows.first { $0.isKeyWindow }
            ?? ASPresentationAnchor(windowScene: scene)
    }
}
