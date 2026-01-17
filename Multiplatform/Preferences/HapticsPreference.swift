//
//  HapticsPreference.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.01.25.
//

import SwiftUI
import ShelfPlayback

struct HapticsPreference<Label: View>: View {
    @Default(.enableHaptics) private var enableHaptics

    let buildLabel: (_ : LocalizedStringKey, _ : String) -> Label

    var body: some View {
        Toggle(isOn: $enableHaptics) {
            buildLabel("preferences.haptics", "hand.tap")
        }
    }
}
