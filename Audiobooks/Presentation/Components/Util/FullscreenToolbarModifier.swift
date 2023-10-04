//
//  FullscreenToolbarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct FullscreenToolbarModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var accentColor: Color = .accentColor
    @Binding var navbarVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 20))
            .symbolVariant(.circle.fill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                navbarVisible ? accentColor : colorScheme == .light ? .black : .white,
                navbarVisible ? .black.opacity(0.1) : .black.opacity(0.25))
            .animation(.easeInOut, value: navbarVisible)
    }
}
