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
    var isLight: Bool? = nil
    @Binding var navigationBarVisible: Bool
    
    func body(content: Content) -> some View {
        let appearance: ColorScheme = isLight == true ? .light : isLight == false ? .dark : colorScheme
        
        content
            .symbolVariant(.circle.fill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                navigationBarVisible ? accentColor : appearance == .light ? .black : .white,
                navigationBarVisible ? .gray.opacity(0.2) : .black.opacity(0.25))
            .animation(.easeInOut, value: navigationBarVisible)
    }
}
