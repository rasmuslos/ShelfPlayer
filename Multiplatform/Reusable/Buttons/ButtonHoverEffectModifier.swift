//
//  ButtonHoverEffectModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.05.24.
//

import SwiftUI

struct ButtonHoverEffectModifier: ViewModifier {
    var padding: CGFloat = 7
    var cornerRadius: CGFloat = 7
    
    var hoverEffect = HoverEffect.highlight
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: cornerRadius))
            .hoverEffect(hoverEffect)
            .padding(-padding)
    }
}
