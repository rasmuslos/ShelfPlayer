//
//  WelcomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI

struct WelcomeView: View {
    @State private var connectionAddViewPresented = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 8) {
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
            }
            
            Spacer()
            
            Button("login.prompt") {
                connectionAddViewPresented.toggle()
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        // .modifier(ConnectionAddSheetModifier(isPresented: $connectionAddViewPresented))
        .sheet(isPresented: $connectionAddViewPresented) {
            NavigationStack {
                ConnectionsManageView()
            }
        }
    }
}

#Preview {
    WelcomeView()
}
