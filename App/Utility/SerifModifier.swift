//
//  SerifModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.05.24.
//

import SwiftUI
import ShelfPlayback

struct SerifModifier: ViewModifier {
    private var enableSerifFont: Bool { AppSettings.shared.enableSerifFont }

    func body(content: Content) -> some View {
        content
            .modify(if: enableSerifFont) {
                $0
                    .fontDesign(.serif)
            }
    }
}
