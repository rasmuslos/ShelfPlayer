//
//  WhatsNewSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.06.25.
//

import SwiftUI
import AppIntents
import CoreSpotlight
import ShelfPlayback

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
                Text(verbatim: "in ") + Text(verbatim: "ShelfPlayer").foregroundStyle(Color.accentColor)
            }
            .bold()
            .font(.largeTitle)
            .padding(.vertical, 40)

            row(systemImage: "chart.xyaxis.line", headline: "Listening Statistics", text: "A new sheet with charts and totals from your listening history.")

            row(systemImage: "speedometer", headline: "Playback Controls", text: "A redesigned playback speed picker, sleep timer, and home screen.")

            row(systemImage: "wand.and.sparkles", headline: "Siri and Shortcuts", text: "More App Intents and widget configurations for Siri, Shortcuts, and the Home Screen.")

            row(systemImage: "accessibility", headline: "Accessibility", text: "Updates to playback, navigation, and onboarding for VoiceOver and assistive technologies.")
        }
        .safeAreaInset(edge: .bottom) {
            Button("action.proceed") {
                AppSettings.shared.lastWhatsNewVersion = ShelfPlayerKit.currentWhatsNewVersion
                satellite.dismissSheet()

                Task {
                    try? await IntentDonationManager.shared.deleteDonations(matching: .intentType(StartIntent.self))
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .buttonSizing(.flexible)
            .padding(.top, 8)
            .padding(.horizontal, 20)
        }
        .interactiveDismissDisabled()
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
