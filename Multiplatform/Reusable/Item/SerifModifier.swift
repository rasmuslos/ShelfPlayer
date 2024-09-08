//
//  SerifModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.24.
//

import SwiftUI
import Defaults

internal struct SerifModifier: ViewModifier {
    @Default(.useSerifFont) private var useSerifFont
    
    func body(content: Content) -> some View {
        if useSerifFont {
            content
                .fontDesign(.serif)
        } else {
            content
        }
    }
}
