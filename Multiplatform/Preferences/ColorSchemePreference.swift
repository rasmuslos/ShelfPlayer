//
//  ColorSchemePreference.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 22.07.25.
//

import SwiftUI
import ShelfPlayback

struct ColorSchemePreference<Label: View>: View {
    @Default(.colorScheme) private var colorScheme
    
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
