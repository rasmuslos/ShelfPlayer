//
//  CircularProgressIndicator.swift
//  ShelfFoundation
//

import SwiftUI

public struct CircularProgressIndicator: View {
    let progress: Double
    let background: Color
    let tint: Color

    public init(completed progress: Double, background: Color = .secondary.opacity(0.3), tint: Color = .accentColor) {
        self.progress = progress.clamped(to: 0...1)
        self.background = background
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(background, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: .init(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityElement()
        .accessibilityValue(Text(progress, format: .percent))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    CircularProgressIndicator(completed: 0.65)
        .frame(width: 40, height: 40)
}
