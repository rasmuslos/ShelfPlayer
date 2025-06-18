//
//  WhatsNewSheet.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.06.25.
//

import SwiftUI
import CoreSpotlight

struct WhatsNewSheet: View {
    @Environment(Satellite.self) private var satellite
    @State private var isLoading = false
    
    private static nonisolated var defaults: UserDefaults {
        #if ENABLE_CENTRALIZED
        UserDefaults.shared
        #else
        UserDefaults.standard
        #endif
    }
    
    @ViewBuilder
    private func row(systemImage: String, headline: String, text: String) -> some View {
        HStack(spacing: 0) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .frame(width: 36)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading) {
                Text(headline)
                    .font(.headline)
                
                Text(text)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .padding(.leading, 20)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text(verbatim: "What's New")
                Text(verbatim: "in ")
                + Text(verbatim: "ShelfPlayer")
                    .foregroundStyle(Color.accentColor)
            }
            .bold()
            .font(.title)
            .padding(.vertical, 40)
            
            row(systemImage: "gauge.with.dots.needle.67percent", headline: "Listened Today", text: "Track your daily listening progress at a glance. See how much you’ve listened today, right from the home screen.")

            row(systemImage: "person.fill", headline: "Narrators", text: "Explore audiobooks by your favorite narrators. Tap a voice you love to discover more titles they’ve brought to life.")

            row(systemImage: "widget.small.badge.plus", headline: "Widgets & App Intents", text: "Add ShelfPlayer widgets to your Lock Screen or Home Screen. Use Shortcuts for instant playback control.")

            row(systemImage: "ladybug.slash.fill", headline: "Rewritten Internals", text: "Faster, smoother, more reliable. ShelfPlayer’s core has been rebuilt from the ground up for a better experience.")
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 2) {
                Text(verbatim: "Proceeding removes all stored data.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                
                Button {
                    proceed()
                } label: {
                    ZStack {
                        Text("action.proceed")
                            .frame(maxWidth: .infinity)
                            .hidden()
                        
                        if isLoading {
                            ProgressView()
                                .frame(height: 0)
                                .scaleEffect(0.5)
                        } else {
                            Text("action.proceed")
                                .frame(maxWidth: .infinity)
                                .opacity(isLoading ? 0 : 1)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.vertical, 4)
                .padding(.horizontal, 20)
            }
            .background(.bar)
        }
    }
    
    private nonisolated func proceed() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            Self.defaults.removeAll()
            
            try? await CSSearchableIndex(name: "ShelfPlayer_Items", protectionClass: .completeUntilFirstUserAuthentication).deleteAllSearchableItems()
            
            let documentsURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            for path in ["images", "tracks"] {
                try? FileManager.default.removeItem(at: documentsURL.appending(path: path))
            }
            
            await MainActor.run {
                isLoading = false
            }
            
            await satellite.dismissSheet()
        }
    }
    
    static var shouldDisplay: Bool {
        defaults.object(forKey: "token") != nil
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
