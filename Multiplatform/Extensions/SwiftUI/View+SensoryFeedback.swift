//
//  View+SensoryFeedback.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.01.25.
//

import SwiftUI
import ShelfPlayback

extension View {
    func hapticFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        modifier(ConditionalSensoryFeedbackModifier(feedback: feedback, trigger: trigger))
    }
}

private struct ConditionalSensoryFeedbackModifier<T: Equatable>: ViewModifier {
    let feedback: SensoryFeedback
    let trigger: T

    @Default(.enableHaptics) private var enableHaptics

    func body(content: Content) -> some View {
        if enableHaptics {
            content
                .sensoryFeedback(feedback, trigger: trigger)
        } else {
            content
        }
    }
}
