//
//  View+UniversalContentShape.swift
//  ShelfFoundation
//

import SwiftUI

public extension View {
    func universalContentShape<S: Shape>(_ shape: S) -> some View {
        #if os(iOS)
        contentShape([.accessibility, .dragPreview, .hoverEffect, .interaction], shape)
        #else
        contentShape([.accessibility, .dragPreview, .interaction], shape)
        #endif
    }
}
