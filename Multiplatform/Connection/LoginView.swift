//
//  LoginView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import BetterSafariView
import CommonCrypto
import ShelfPlayerKit

struct LoginView: View {
    @State private var loginSheetPresented = false
    @State private var loginFlowState: LoginFlowState = .server
    
    @State private var server = "" // AudiobookshelfClient.shared.serverURL?.absoluteString ?? "https://"
    @State private var username = ""
    @State private var password = ""
    
    @State private var serverVersion: String?
    @State private var loginError: LoginError?
    
    private let verifier = String.random(length: 100)
    @State private var openIDLoginURL: URL?
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 108)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 28)
            
            Text("login.welcome")
                .bold()
                .font(.title)
                .fontDesign(.serif)
            Text("login.text")
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                loginSheetPresented.toggle()
            } label: {
                Label("login.prompt", systemImage: "person.badge.plus")
                    .labelStyle(.titleOnly)
                    .contentShape(.rect)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 60)
            }
            .background(Color.accentColor, in: .rect(cornerRadius: 12))
            .foregroundStyle(.background)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $loginSheetPresented) {
            NavigationStack {
                switch loginFlowState {
                case .server, .credentialsLocal:
                    Form {
                        Section {
                            if loginFlowState == .server {
                                TextField("login.server", text: $server)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else if loginFlowState == .credentialsLocal {
                                TextField("login.username", text: $username)
                                SecureField("login.password", text: $password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button {
                                flowStep()
                            } label: {
                                Text("login.next")
                            }
                        } header: {
                            if let serverVersion = serverVersion {
                                Text("login.version \(serverVersion)")
                            } else {
                                Text("login.title")
                            }
                        } footer: {
                            Group {
                                switch loginError {
                                case .server:
                                    Text("login.error.server")
                                case .url:
                                    Text("login.error.url")
                                case .failed:
                                    Text("login.error.failed")
                                case nil:
                                    Text(verbatim: "")
                                }
                            }
                            .foregroundStyle(.red)
                        }
                        
                        if loginFlowState == .server {
                            Section {
                                NavigationLink(destination: CustomHeaderEditView()) {
                                    Label("login.customHTTPHeaders", systemImage: "lock.shield.fill")
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onSubmit(flowStep)
                case .credentialsOpenID:
                    if let openIDLoginURL = openIDLoginURL {
                        ProgressIndicator()
                            .webAuthenticationSession(isPresented: .constant(true)) {
                                WebAuthenticationSession(url: openIDLoginURL, callbackURLScheme: "shelfplayer", completionHandler: self.openIDCallback)
                                    .prefersEphemeralWebBrowserSession(true)
                            }
                    } else {
                        ProgressIndicator()
                            .task { await fetchOpenIDLoginURL() }
                    }
                case .credentialsSelect:
                    Form {
                        Section {
                            Button {
                                loginFlowState = .credentialsOpenID
                            } label: {
                                Text("login.openid")
                            }
                            
                            Button {
                                loginFlowState = .credentialsLocal
                            } label: {
                                Text("login.local")
                            }
                        } header: {
                            Text("login.version \(serverVersion!)")
                        } footer: {
                            Text("login.openid.urlScheme")
                            
                            if loginError == .failed {
                                Text("login.error.failed")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                case .setup:
                    Text("login.setup")
                        .padding()
                case .serverLoading, .credentialsLoading:
                    VStack {
                        ProgressIndicator()
                        Text("login.loading")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: Functions

extension LoginView {
    private func flowStep() {
        if loginFlowState == .server {
            loginFlowState = .serverLoading
            
            // Verify url format
            do {
                // try AudiobookshelfClient.shared.store(serverUrl: server)
            } catch {
                loginError = .url
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            Task {
                do {
                    /*
                    let status = try await AudiobookshelfClient.shared.status()
                    
                    serverVersion = status.serverVersion
                    
                    if status.authMethods.count == 2 {
                        loginFlowState = .credentialsSelect
                    } else if status.authMethods.contains("local") {
                        loginFlowState = .credentialsLocal
                    } else if status.authMethods.contains("openid") {
                        loginFlowState = .credentialsOpenID
                    }
                     */
                } catch {
                    loginError = .server
                    loginFlowState = .server
                    
                    return
                }
                
                loginError = nil
            }
        } else if loginFlowState == .credentialsLocal {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    // let token = try await AudiobookshelfClient.shared.login(username: username, password: password)
                    // AudiobookshelfClient.shared.store(token: token)
                } catch {
                    loginError = .failed
                    loginFlowState = .credentialsLocal
                }
            }
        }
    }
    
    enum LoginFlowState {
        case server
        case serverLoading
        
        case credentialsLocal
        case credentialsOpenID
        case credentialsSelect
        case credentialsLoading
        
        case setup
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}

private extension LoginView {
    func fetchOpenIDLoginURL() async {
        do {
            // openIDLoginURL = try await AudiobookshelfClient.shared.openIDLoginURL(verifier: verifier)
        } catch {
            loginError = .failed
            loginFlowState = .server
        }
    }
    
    func openIDCallback(url: URL?, error: Error?) {
        loginFlowState = .credentialsLoading
        
        if error == nil, let url = url {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value,
               let state = components?.queryItems?.first(where: { $0.name == "state" })?.value {
                Task {
                    /*
                    if let token = try? await AudiobookshelfClient.shared.openIDExchange(code: code, state: state, verifier: verifier) {
                        AudiobookshelfClient.shared.store(token: token)
                    } else {
                        openIDLoginURL = nil
                        
                        loginError = .failed
                        loginFlowState = .server
                    }
                     */
                }
                
                return
            }
        }
        
        openIDLoginURL = nil
        
        loginError = .failed
        loginFlowState = .server
    }
}

#Preview {
    LoginView()
}
