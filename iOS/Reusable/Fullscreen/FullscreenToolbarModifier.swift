//
//  FullscreenToolbarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct FullscreenToolbarModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let navigationBarVisible: Bool
    
    var isLight: Bool? = nil
    var accentColor: Color = .accentColor
    
    func body(content: Content) -> some View {
        let appearance: ColorScheme = isLight == true ? .light : isLight == false ? .dark : colorScheme
        
        content
            .symbolVariant(.circle.fill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                navigationBarVisible ? accentColor : appearance == .light ? .black : .white,
                navigationBarVisible ? .gray.opacity(0.1) : .black.opacity(0.25))
    }
}
