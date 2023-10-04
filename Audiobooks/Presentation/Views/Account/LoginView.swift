//
//  LoginView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 16.09.23.
//

import SwiftUI

struct LoginView: View {
    var callback : () -> ()
    
    @State var loginSheetPresented = false
    @State var loginFlowState: LoginFlowState = .server
    
    @State var server = AudiobookshelfClient.shared.serverUrl?.absoluteString ?? ""
    @State var username = ""
    @State var password = ""
    
    @State var serverVersion: String?
    @State var errorText: String?
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Logo")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.bottom, 50)
            
            Text("Welcome to Audiobooks")
                .font(.headline)
                .fontDesign(.serif)
            Text("Please login to get started")
                .font(.subheadline)
            
            Button {
                loginSheetPresented.toggle()
            } label: {
                Text("Login with ABS")
            }
            .buttonStyle(LargeButtonStyle())
            .padding()
            
            Spacer()
            
            Text("Devloped by Rasmus Krämer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $loginSheetPresented, content: {
            switch loginFlowState {
            case .server, .credentials:
                Form {
                    Section {
                        if loginFlowState == .server {
                            TextField("Server URL", text: $server)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else if loginFlowState == .credentials {
                            TextField("Username", text: $username)
                            SecureField("Password", text: $password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        
                        Button {
                            flowStep()
                        } label: {
                            Text("Next")
                        }
                    } header: {
                        Text("Login")
                    } footer: {
                        if let errorText = errorText {
                            Text(errorText)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .onSubmit(flowStep)
            case .serverLoading, .credentialsLoading:
                VStack {
                    ProgressView()
                    Text("Loading")
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
                errorText = "Invalid server URL (Format: http(s)://host:port)"
                loginFlowState = .server
                
                return
            }
            
            // Verify server
            Task {
                do {
                    try await AudiobookshelfClient.shared.ping()
                } catch {
                    errorText =  "Audiobookshelf server not found"
                    loginFlowState = .server
                    
                    return
                }
                
                errorText = nil
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
                    errorText = "Login failed"
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
}

#Preview {
    LoginView() {
        print("Login flow finished")
    }
}
