//
//  ColorSchemePreference.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 22.07.25.
//

import SwiftUI
import ShelfPlayback

struct ColorSchemePreference: View {
    @Default(.colorScheme) private var colorScheme
    
    var body: some View {
        Picker("preferences.colorScheme", systemImage: "lightspectrum.horizontal", selection: $colorScheme) {
            ForEach(ConfiguredColorScheme.allCases, id: \.hashValue) {
                Text($0.label)
                    .tag($0)
            }
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
