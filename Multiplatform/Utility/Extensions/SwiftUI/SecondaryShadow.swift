//
//  Shadow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 11.10.24.
//

import Foundation
import SwiftUI

internal struct SecondaryShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let radius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .shadow(color: (colorScheme == .dark ? Color.gray.opacity(0.5) : .black).opacity(opacity), radius: radius)
    }
}

internal extension View {
    @ViewBuilder
    func secondaryShadow(radius: CGFloat = 12, opacity: Double = 0.2) -> some View {
        modifier(SecondaryShadow(radius: radius, opacity: opacity))
    }
}
