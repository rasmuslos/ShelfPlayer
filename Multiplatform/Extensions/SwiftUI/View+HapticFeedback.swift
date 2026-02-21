//
//  View+HapticFeedback.swift
//  ShelfPlayer
//
//  Created by Codex on 21.02.26.
//

import SwiftUI
import ShelfPlayback

private struct SettingsAwareSensoryFeedbackModifier<Trigger: Equatable>: ViewModifier {
    let feedback: SensoryFeedback
    let trigger: Trigger

    @Default(.enableHapticFeedback) private var enableHapticFeedback

    @ViewBuilder
    func body(content: Content) -> some View {
        if enableHapticFeedback {
            content
                .sensoryFeedback(feedback, trigger: trigger)
        } else {
            content
        }
    }
}

extension View {
    func hapticFeedback<Trigger: Equatable>(_ feedback: SensoryFeedback, trigger: Trigger) -> some View {
        modifier(SettingsAwareSensoryFeedbackModifier(feedback: feedback, trigger: trigger))
    }
}
