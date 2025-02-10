//
//  SerifModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.24.
//

import SwiftUI
import Defaults

internal struct SerifModifier: ViewModifier {
    @Default(.enableSerifFont) private var enableSerifFont
    
    func body(content: Content) -> some View {
        if enableSerifFont {
            content
                .fontDesign(.serif)
        } else {
            content
        }
    }
}
