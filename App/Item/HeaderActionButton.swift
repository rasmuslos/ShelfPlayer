//
//  HeaderActionButton.swift
//  ShelfPlayer
//

import SwiftUI

struct HeaderActionButton<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .font(.body)
            .frame(width: 44, height: 44)
            .background(.secondary.opacity(0.15), in: .circle)
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .contentShape(.hoverEffect, .circle)
            .hoverEffect(.highlight)
    }
}
