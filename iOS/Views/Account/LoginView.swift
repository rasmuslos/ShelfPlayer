//
//  LoginView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI
import AudiobooksKit

struct LoginView: View {
    var callback : () -> ()
    
    @State var loginSheetPresented = false
    @State var loginFlowState: LoginFlowState = .server
    
    @State var server = AudiobookshelfClient.shared.serverUrl?.absoluteString ?? ""
    @State var username = ""
    @State var password = ""
    
    @State var serverVersion: String?
    @State var loginError: LoginError?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("login.welcome")
                .font(.headline)
                .fontDesign(.serif)
            Text("login.text")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("login.promt")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
            
            Spacer()
            
            #if DEBUG
            Text("developedBy")
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
        }
        .sheet(isPresented: $loginSheetPresented, content: {
            switch loginFlowState {
            case .server, .credentials:
                Form {
                    Section {
                        if loginFlowState == .server {
                            TextField("login.server", text: $server)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else if loginFlowState == .credentials {
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
                        Text("login.title")
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
                }
                .onSubmit(flowStep)
            case .serverLoading, .credentialsLoading:
                VStack {
                    ProgressView()
                    Text("login.loading")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        })
    }
}

// MARK: Functions

extension LoginView {
    private func flowStep() {
        if loginFlowState == .server {
            loginFlowState = .serverLoading
            
            // Verify url format
            do {
                try AudiobookshelfClient.shared.setServerUrl(server)
            } catch {
                loginError = .url
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            Task {
                do {
                    try await AudiobookshelfClient.shared.ping()
                } catch {
                    loginError = .server
                    loginFlowState = .server
                    
                    return
                }
                
                loginError = nil
                loginFlowState = .credentials
            }
        } else if loginFlowState == .credentials {
            loginFlowState = .credentialsLoading
            
            Task {
                do {
                    let token = try await AudiobookshelfClient.shared.login(username: username, password: password)
                    
                    AudiobookshelfClient.shared.setToken(token)
                    callback()
                } catch {
                    loginError = .failed
                    loginFlowState = .credentials
                }
            }
        }
    }
    
    enum LoginFlowState {
        case server
        case serverLoading
        case credentials
        case credentialsLoading
    }
    enum LoginError {
        case server
        case url
        case failed
    }
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
