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
    
    init(strategies: [AuthorizationStrategy]? = nil, isLoading: Binding<Bool>, apiClient: APIClient, callback: @escaping Callback) {
        _strategies = .init(initialValue: strategies)
        _isLoading = isLoading
        
        self.apiClient = apiClient
        self.callback = callback
        
        if strategies?.count == 1 {
            _strategy = .init(initialValue: strategies?.first)
        }
    }
    
    @Binding var isLoading: Bool
    
    @State private var strategy: AuthorizationStrategy?
    @State private var strategies: [AuthorizationStrategy]? = nil
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var verifier = String.random(length: 100)
    
    @State private var notifyError = false
    
    let callback: Callback
    let apiClient: APIClient
    
    private let authenticationSessionPresentationContextProvider = AuthenticationSessionPresentationContextProvider()
    
    var body: some View {
        if let strategies {
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
                            
                            SecureField("connection.add.password", text: $password)
                                .textContentType(.password)
                            
                            Button("connection.add.proceed") {
                                authorize()
                            }
                            .disabled(isLoading)
                        case .openID:
                            Button("action.retry") {
                                authorize()
                            }
                            .disabled(isLoading)
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
            } else {
                Picker("connection.add.strategy.select", selection: $strategy) {
                    ForEach(strategies) {
                        Text($0.label)
                            .tag($0)
                    }
                }
                .pickerStyle(.inline)
            }
        }
    }
    
    func authorize() {
        Task {
            do {
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
                notifyError.toggle()
                isLoading = false
            }
        }
        
        // qq
        func authorizeLocal() async throws {
            guard !username.isEmpty else {
                notifyError.toggle()
                return
            }
            
            let (username, accessToken, refreshToken) = try await apiClient.login(username: username, password: password)
            callback(username, accessToken, refreshToken)
        }
        func authorizeOpenID() async throws {
            let session = try await ASWebAuthenticationSession(url: apiClient.openIDLoginURL(verifier: verifier), callback: .customScheme("shelfplayer"), completionHandler: callback)
            
            session.presentationContextProvider = authenticationSessionPresentationContextProvider
            session.prefersEphemeralWebBrowserSession = true
            session.additionalHeaderFields = await Dictionary(uniqueKeysWithValues: apiClient.requestHeaders.map { ($0.key, $0.value) })
            
            session.start()
            
            // hell
            func callback(_ url: URL?, _ error: (any Error)?) -> Void {
                Task {
                    guard error == nil, let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems, let code = queryItems.first(where: { $0.name == "code" })?.value, let state = queryItems.first(where: { $0.name == "state" })?.value else {
                        self.isLoading = false
                        self.notifyError.toggle()
                        
                        return
                    }
                    
                    do {
                        let (username, accessToken, refreshToken) = try await apiClient.openIDExchange(code: code, state: state, verifier: verifier)
                        self.callback(username, accessToken, refreshToken)
                    } catch {
                        self.isLoading = false
                        self.notifyError.toggle()
                    }
                }
            }
        }
    }
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

private final class AuthenticationSessionPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
