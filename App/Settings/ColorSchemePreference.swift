//
//  ColorSchemePreference.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 22.07.25.
//

import SwiftUI
import ShelfPlayback

struct ColorSchemePreference<Label: View>: View {
    @State private var colorScheme: ConfiguredColorScheme = AppSettings.shared.colorScheme

    let buildLabel: (_ : LocalizedStringKey, _ : String) -> Label

    var body: some View {
        Picker(selection: $colorScheme) {
            ForEach(ConfiguredColorScheme.allCases, id: \.hashValue) {
                Text($0.label)
                    .tag($0)
            }
        } label: {
            buildLabel("preferences.colorScheme", "lightspectrum.horizontal")
        }
        .onChange(of: colorScheme) {
            AppSettings.shared.colorScheme = colorScheme
            AppEventSource.shared.appearanceDidChange.send()
        }
    }
}

extension ConfiguredColorScheme {
    var label: LocalizedStringKey {
        switch self {
            case .system:
                "preferences.colorScheme.system"
            case .dark:
                "preferences.colorScheme.dark"
            case .light:
                "preferences.colorScheme.light"
        }
    }
}
