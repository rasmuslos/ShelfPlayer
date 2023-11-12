//
//  ContentView.swift
//  tvOS
//
//  Created by Rasmus Krämer on 12.11.23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("token") var token: String = ""
    
    @State var server: String = ""
    @State var username: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack {
            Text(token)
                .fontDesign(.monospaced)
            
            // forms fuck up the styling of these because of course
            TextField("Server", text: $server)
            TextField("Username", text: $username)
            TextField("Password", text: $password)
            
            Button {
                Task {
                    try? AudiobookshelfClient.shared.setServerUrl(server)
                    if let token = try? await AudiobookshelfClient.shared.login(username: username, password: password) {
                        AudiobookshelfClient.shared.setToken(token)
                    }
                }
            } label: {
                Text("Login")
            }
        }
    }
}

#Preview {
    ContentView()
}
