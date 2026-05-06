//
//  WelcomeView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.12.24.
//

import SwiftUI
import ShelfPlayback

struct WelcomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(Satellite.self) private var satellite

    private var logoSize: CGFloat {
        horizontalSizeClass == .regular ? 140 : 108
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    Image(decorative: "Logo")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: logoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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

                    Text("By using ShelfPlayer you agree to the [Terms of Service](https://github.com/rasmuslos/ShelfPlayer/blob/main/ToS.md)")
                        .foregroundStyle(.primary)
                    .buttonStyle(.plain)
                }
                .font(.caption2)
                .padding(.bottom, 4)

                Button("setup.welcome.action") {
                    satellite.present(.addConnection)
                }
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("preferences.support", systemImage: "lifepreserver") {
                        satellite.present(.debugPreferences)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    WelcomeView()
        .previewEnvironment()
}
#endif
