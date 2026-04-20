//
//  WhatsNewSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.06.25.
//

import SwiftUI
import CoreSpotlight

struct WhatsNewSheet: View {
    @Environment(Satellite.self) private var satellite

    @ViewBuilder
    private func row(systemImage: String, headline: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.accentColor)
                .frame(width: 60)

            VStack(alignment: .leading) {
                Text(headline)
                    .font(.headline)

                Text(text)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .padding(.leading, 20)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 32)
    }

    var body: some View {
        ScrollView {
            VStack {
                Text(verbatim: "What's New")
                Text("in \(Text(verbatim: "ShelfPlayer").foregroundStyle(Color.accentColor))")
            }
            .bold()
            .font(.largeTitle)
            .padding(.vertical, 40)

            row(systemImage: "wifi.slash", headline: "Seamless Listening Everywhere", text: "ShelfPlayer now delivers a more unified offline and sync experience, so your listening continues smoothly across devices and network conditions.")

            row(systemImage: "car.fill", headline: "Refined CarPlay Experience", text: "CarPlay interaction is now more polished and dependable, providing confident control during every drive.")

            row(systemImage: "sparkles", headline: "Elevated Overall Quality", text: "This release brings broad quality and performance enhancements that make ShelfPlayer feel faster, steadier, and more premium throughout.")
        }
        .safeAreaInset(edge: .bottom) {
            Button("action.proceed") {
                satellite.dismissSheet()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .buttonSizing(.flexible)
            .padding(.top, 8)
            .padding(.horizontal, 20)
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            WhatsNewSheet()
        }
        .previewEnvironment()
}
#endif
