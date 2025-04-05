//
//  WelcomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isConnectionAddViewPresented = false
    
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
                
                Text("setup.welcome")
                    .bold()
                    .font(.title)
                    .fontDesign(.serif)
                
                Text("setup.welcome.description")
                    .padding(20)
            }
            
            Spacer()
            
            Button("setup.welcome.action") {
                isConnectionAddViewPresented.toggle()
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isConnectionAddViewPresented) {
            ConnectionAddView() {
                isConnectionAddViewPresented = false
            }
        }
    }
}

#Preview {
    WelcomeView()
}
