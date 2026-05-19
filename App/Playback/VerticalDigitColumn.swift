//
//  VerticalDigitColumn.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.05.26.
//

import SwiftUI
import ShelfPlayback

/// Vertical wheel-style digit column. Users drag up/down to scroll through integer values
/// in `range`; the value at the center is the selection.
///
/// Drag state is internal so the parent body does not rebuild on every gesture event. The
/// `value` binding updates while dragging so the parent can show a live preview, and
/// `onCommit` only fires on drag end — letting callers defer expensive side effects (network
/// writes, audio reconfigure, …) until the gesture settles.
///
/// Standard iOS wheel convention: dragging up scrolls the column up, bringing higher values
/// to the center.
struct VerticalDigitColumn: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    let primaryColor: Color
    let secondaryColor: Color

    var accessibilityLabel: LocalizedStringKey = ""
    /// Values within `range` that are visible but not selectable. Drag snaps to the nearest
    /// enabled value and the smooth scroll position is clamped to the enabled bounds, so the
    /// disabled digits read as "greyed out and locked out" rather than scrollable-but-rejected.
    var disabledValues: Set<Int> = []
    var onDragStart: () -> Void = {}
    var onCommit: (Int) -> Void = { _ in }

    @State private var dragAnchor: Double?
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging = false

    private let rowHeight: CGFloat = 36
    private let visibleRows = 5

    private var enabledBounds: ClosedRange<Int> {
        let enabled = range.filter { !disabledValues.contains($0) }
        guard let lo = enabled.min(), let hi = enabled.max() else { return value...value }
        return lo...hi
    }

    private var smoothPosition: Double {
        guard let anchor = dragAnchor else { return Double(value) }
        let delta = -dragTranslation / rowHeight
        return clamp(anchor + delta)
    }

    private var snappedValue: Int {
        nearestEnabled(to: Int(smoothPosition.rounded()))
    }

    private func clamp(_ v: Double) -> Double {
        let bounds = enabledBounds
        return max(Double(bounds.lowerBound), min(Double(bounds.upperBound), v))
    }

    private func nearestEnabled(to candidate: Int) -> Int {
        if range.contains(candidate) && !disabledValues.contains(candidate) {
            return candidate
        }
        let span = range.upperBound - range.lowerBound
        for offset in 1...max(1, span) {
            let below = candidate - offset
            if below >= range.lowerBound, !disabledValues.contains(below) { return below }
            let above = candidate + offset
            if above <= range.upperBound, !disabledValues.contains(above) { return above }
        }
        return value
    }

    var body: some View {
        let height = rowHeight * CGFloat(visibleRows)

        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(primaryColor.opacity(0.08))
                .frame(height: rowHeight)

            DigitCanvas(
                smoothPosition: smoothPosition,
                rangeLower: range.lowerBound,
                rangeUpper: range.upperBound,
                rowHeight: rowHeight,
                primaryColor: primaryColor,
                disabledValues: disabledValues
            )
            .frame(height: height)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.22),
                    .init(color: .black, location: 0.78),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            )
            .animation(isDragging ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: smoothPosition)
        }
        .frame(height: height)
        .contentShape(.rect)
        .hapticFeedback(.selection, trigger: snappedValue)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if dragAnchor == nil {
                        dragAnchor = Double(value)
                        isDragging = true
                        onDragStart()
                    }
                    dragTranslation = g.translation.height

                    let snapped = snappedValue
                    if value != snapped {
                        value = snapped
                    }
                }
                .onEnded { _ in
                    let final = snappedValue
                    dragAnchor = nil
                    value = final
                    onCommit(final)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isDragging = false
                        dragTranslation = 0
                    }
                }
        )
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(Text(verbatim: "\(value)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
                case .increment:
                    let next = nextEnabled(after: value, ascending: true)
                    value = next
                    onCommit(next)
                case .decrement:
                    let next = nextEnabled(after: value, ascending: false)
                    value = next
                    onCommit(next)
                @unknown default:
                    break
            }
        }
        .onChange(of: disabledValues) { _, _ in
            let snapped = nearestEnabled(to: value)
            if snapped != value {
                value = snapped
            }
        }
    }

    private func nextEnabled(after current: Int, ascending: Bool) -> Int {
        let step = ascending ? 1 : -1
        var candidate = current + step
        while range.contains(candidate) {
            if !disabledValues.contains(candidate) { return candidate }
            candidate += step
        }
        return current
    }
}

private struct DigitCanvas: View, @preconcurrency Animatable {
    var smoothPosition: Double
    let rangeLower: Int
    let rangeUpper: Int
    let rowHeight: CGFloat
    let primaryColor: Color
    let disabledValues: Set<Int>

    var animatableData: Double {
        get { smoothPosition }
        set { smoothPosition = newValue }
    }

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let centerY = size.height / 2

            for v in rangeLower...rangeUpper {
                let distance = Double(v) - smoothPosition
                let rowY = centerY + CGFloat(distance) * rowHeight

                if rowY < -rowHeight || rowY > size.height + rowHeight { continue }

                let absDist = abs(distance)
                let disabled = disabledValues.contains(v)
                let weight: Font.Weight = (!disabled && absDist < 0.5) ? .bold : .regular
                let baseOpacity: Double = max(0.25, 1.0 - absDist * 0.28)
                let opacity: Double = disabled ? 0.18 : baseOpacity

                let text = Text(verbatim: "\(v)")
                    .font(.system(.title2, weight: weight))
                    .monospacedDigit()
                    .foregroundStyle(primaryColor.opacity(opacity))

                context.draw(text, at: CGPoint(x: size.width / 2, y: rowY), anchor: .center)
            }
        }
    }
}

#if DEBUG
private struct VerticalDigitColumnSinglePreview: View {
    @State private var value: Int = 7
    @State private var commitCount = 0

    var body: some View {
        VStack(spacing: 16) {
            Text(verbatim: "Value: \(value)")
                .font(.headline)

            VerticalDigitColumn(
                value: $value,
                range: 0...9,
                primaryColor: .primary,
                secondaryColor: .secondary,
                accessibilityLabel: "Digit",
                onCommit: { _ in commitCount += 1 }
            )
            .frame(width: 80)

            Text(verbatim: "Commits: \(commitCount)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

private struct VerticalDigitColumnTimerPreview: View {
    @State private var hours: Int = 1
    @State private var minutesTens: Int = 3
    @State private var minutesOnes: Int = 0
    var onMeshBackground: Bool = false

    private var primary: Color { onMeshBackground ? .white : .primary }
    private var secondary: Color { onMeshBackground ? .white.opacity(0.6) : .secondary }

    private var totalMinutes: Int { hours * 60 + minutesTens * 10 + minutesOnes }

    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: String(format: "%d:%d%d", hours, minutesTens, minutesOnes))
                .font(.system(size: 64, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(primary)

            HStack(alignment: .center, spacing: 8) {
                VerticalDigitColumn(
                    value: $hours,
                    range: 0...9,
                    primaryColor: primary,
                    secondaryColor: secondary,
                    accessibilityLabel: "Hours"
                )
                .frame(maxWidth: .infinity)

                Text(verbatim: ":")
                    .font(.system(.title, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(primary.opacity(0.6))

                VerticalDigitColumn(
                    value: $minutesTens,
                    range: 0...5,
                    primaryColor: primary,
                    secondaryColor: secondary,
                    accessibilityLabel: "Minute tens"
                )
                .frame(maxWidth: .infinity)

                VerticalDigitColumn(
                    value: $minutesOnes,
                    range: 0...9,
                    primaryColor: primary,
                    secondaryColor: secondary,
                    accessibilityLabel: "Minute ones"
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Text(verbatim: "Total: \(totalMinutes) min")
                .font(.footnote)
                .foregroundStyle(secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Single column") {
    VerticalDigitColumnSinglePreview()
}

#Preview("HH:MM picker") {
    VerticalDigitColumnTimerPreview()
}

#Preview("HH:MM on mesh") {
    ZStack {
        LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        VerticalDigitColumnTimerPreview(onMeshBackground: true)
    }
    .preferredColorScheme(.dark)
}
#endif
