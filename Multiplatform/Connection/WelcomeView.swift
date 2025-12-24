//
//  WelcomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import ShelfPlayback

struct WelcomeView: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                Image(decorative: "Logo")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.bottom, 28)
                
                Text("setup.welcome")
                    .bold()
                    .font(.title)
                    .fontDesign(.serif)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/LICENSE")!) {
                        Text(verbatim: "License")
                    }
                    Text(verbatim: " | ")
                    Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/Privacy.md")!) {
                        Text(verbatim: "Privacy Policy")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/blob/main/ToS.md")!) {
                    Text(verbatim: "By using ShelfPlayer you agree to the ")
                        .foregroundStyle(.primary)
                    + Text(verbatim: "Terms of Service")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .font(.caption2)
            .padding(.bottom, 4)
            
            Button("setup.welcome.action") {
                satellite.present(.addConnection)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 8)
        }
    }
}

#if DEBUG
#Preview {
    WelcomeView()
        .previewEnvironment()
}
#endif
