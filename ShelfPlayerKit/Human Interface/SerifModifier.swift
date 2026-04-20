//
//  SerifModifier.swift
//  ShelfFoundation
//

import SwiftUI

public struct SerifModifier: ViewModifier {
    let isActive: Bool

    public init(isActive: Bool = true) {
        self.isActive = isActive
    }

    public func body(content: Content) -> some View {
        if isActive {
            content.fontDesign(.serif)
        } else {
            content
        }
    }
}

public extension View {
    func serifFont(_ isActive: Bool = true) -> some View {
        modifier(SerifModifier(isActive: isActive))
    }
}
