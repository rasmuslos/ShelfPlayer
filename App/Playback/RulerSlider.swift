//
//  RulerSlider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.05.26.
//

import SwiftUI
import ShelfPlayback

/// Horizontal ruler-style slider with major/minor ticks, optional labels, and a centered
/// arrow indicator.
///
/// All drag-gesture state (translation, anchor, isDragging) is owned by this view so the
/// parent body does not rebuild on every gesture event. The `value` binding updates while
/// dragging — letting the parent show a live preview — and `onCommit` fires on drag end
/// so callers can defer expensive side effects (audio rate change, network writes, …) until
/// the gesture settles.
struct RulerSlider: View {
    @Binding var value: Double

    let range: ClosedRange<Double>
    let step: Double
    let tickSpacing: CGFloat

    /// Distance between major ticks expressed in value units. Must be a multiple of `step`.
    let majorStep: Double
    /// Distance between labels expressed in value units. Must be a multiple of `majorStep`.
    let labelStep: Double
    let labelText: (Double) -> Text

    let primaryColor: Color
    let secondaryColor: Color

    var accessibilityLabel: LocalizedStringKey = ""
    var accessibilityValue: (Double) -> Text = { Text(String(format: "%.2f", $0)) }
    var onDragStart: () -> Void = {}
    var onCommit: (Double) -> Void = { _ in }

    @State private var dragAnchor: Double?
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging = false

    private var displayValue: Double {
        guard let anchor = dragAnchor else { return value }
        let delta = -dragTranslation / tickSpacing * step
        return clamp(anchor + delta)
    }

    private func clamp(_ v: Double) -> Double {
        max(range.lowerBound, min(range.upperBound, v))
    }

    private func snap(_ v: Double) -> Double {
        (clamp(v) / step).rounded() * step
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let tickHeight: CGFloat = 40
            let labelSpacing: CGFloat = 6
            let labelHeight: CGFloat = 14

            VStack(spacing: labelSpacing) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(primaryColor)
                    .frame(width: width, height: 10)

                RulerCanvas(
                    value: displayValue,
                    rangeLower: range.lowerBound,
                    rangeUpper: range.upperBound,
                    step: step,
                    tickSpacing: tickSpacing,
                    tickHeight: tickHeight,
                    labelSpacing: labelSpacing,
                    labelHeight: labelHeight,
                    majorStep: majorStep,
                    labelStep: labelStep,
                    labelText: labelText,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor
                )
                .frame(width: width, height: tickHeight + labelSpacing + labelHeight)
                .mask(alignment: .leading) {
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.12),
                        .init(color: .black, location: 0.88),
                        .init(color: .clear, location: 1)
                    ], startPoint: .leading, endPoint: .trailing)
                    .frame(width: width)
                }
                .animation(isDragging ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: displayValue)
            }
            .frame(width: width, height: geo.size.height, alignment: .top)
            .contentShape(.rect)
            .hapticFeedback(.selection, trigger: snap(displayValue))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragAnchor == nil {
                            dragAnchor = value
                            isDragging = true
                            onDragStart()
                        }
                        dragTranslation = g.translation.width

                        let snapped = snap(displayValue)
                        if abs(value - snapped) > 0.001 {
                            value = snapped
                        }
                    }
                    .onEnded { _ in
                        let final = snap(displayValue)
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
            .accessibilityValue(accessibilityValue(value))
            .accessibilityAdjustableAction { direction in
                switch direction {
                    case .increment:
                        let newValue = snap(value + step)
                        value = newValue
                        onCommit(newValue)
                    case .decrement:
                        let newValue = snap(value - step)
                        value = newValue
                        onCommit(newValue)
                    @unknown default:
                        break
                }
            }
        }
    }
}

private struct RulerCanvas: View, @preconcurrency Animatable {
    var value: Double
    let rangeLower: Double
    let rangeUpper: Double
    let step: Double
    let tickSpacing: CGFloat
    let tickHeight: CGFloat
    let labelSpacing: CGFloat
    let labelHeight: CGFloat
    let majorStep: Double
    let labelStep: Double
    let labelText: (Double) -> Text
    let primaryColor: Color
    let secondaryColor: Color

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let centerX = size.width / 2
            let tickCount = Int(((rangeUpper - rangeLower) / step).rounded()) + 1
            let currentIndex = (value - rangeLower) / step
            let offsetX = centerX - CGFloat(currentIndex) * tickSpacing - tickSpacing / 2

            let majorHeight: CGFloat = 24
            let minorHeight: CGFloat = 10
            let labelY = tickHeight + labelSpacing + labelHeight / 2

            for index in 0..<tickCount {
                let tickX = offsetX + CGFloat(index) * tickSpacing + tickSpacing / 2
                if tickX < -8 || tickX > size.width + 8 { continue }

                let v = rangeLower + Double(index) * step
                let major = Self.isMultiple(v, of: majorStep)
                let labeled = Self.isMultiple(v, of: labelStep)

                let height: CGFloat = major ? majorHeight : minorHeight
                let lineWidth: CGFloat = major ? 1.75 : 1
                let opacity: Double = major ? 0.9 : 0.3

                let barRect = CGRect(x: tickX - lineWidth / 2, y: tickHeight - height, width: lineWidth, height: height)
                context.fill(Path(barRect), with: .color(primaryColor.opacity(opacity)))

                if labeled {
                    let text = labelText(v)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(secondaryColor)
                    context.draw(text, at: CGPoint(x: tickX, y: labelY), anchor: .center)
                }
            }
        }
    }

    private static func isMultiple(_ value: Double, of unit: Double) -> Bool {
        guard unit > 0 else { return false }
        let scaled = value / unit
        return abs(scaled - scaled.rounded()) < 0.001
    }
}

#if DEBUG
private struct RulerSliderRatePreview: View {
    @State private var rate: Double = 1.0
    @State private var commitCount = 0
    var onMeshBackground: Bool = false

    private var primary: Color { onMeshBackground ? .white : .primary }
    private var secondary: Color { onMeshBackground ? .white.opacity(0.6) : .secondary }

    var body: some View {
        VStack(spacing: 20) {
            Text(rate, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 72, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(primary)

            RulerSlider(
                value: $rate,
                range: 0.1...4.0,
                step: 0.1,
                tickSpacing: 16,
                majorStep: 0.5,
                labelStep: 0.5,
                labelText: { Text($0, format: .number.precision(.fractionLength(1))) },
                primaryColor: primary,
                secondaryColor: secondary,
                accessibilityLabel: "Rate",
                accessibilityValue: { Text(String(format: "%.1fx", $0)) },
                onCommit: { _ in commitCount += 1 }
            )
            .frame(height: 84)

            Text(verbatim: "Commits: \(commitCount)")
                .font(.footnote)
                .foregroundStyle(secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RulerSliderSleepPreview: View {
    @State private var minutes: Double = 30

    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "\(Int(minutes)) min")
                .font(.system(size: 56, weight: .bold))
                .monospacedDigit()

            RulerSlider(
                value: $minutes,
                range: 1...180,
                step: 1,
                tickSpacing: 12,
                majorStep: 5,
                labelStep: 15,
                labelText: { Text(verbatim: "\(Int($0.rounded()))") },
                primaryColor: .primary,
                secondaryColor: .secondary,
                accessibilityLabel: "Minutes",
                accessibilityValue: { Text("\(Int($0)) minutes") }
            )
            .frame(height: 84)
        }
        .padding(24)
    }
}

#Preview("Rate ruler") {
    RulerSliderRatePreview()
}

#Preview("Rate ruler on mesh") {
    ZStack {
        LinearGradient(colors: [.purple, .indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        RulerSliderRatePreview(onMeshBackground: true)
    }
    .preferredColorScheme(.dark)
}

#Preview("Sleep-timer ruler") {
    RulerSliderSleepPreview()
}
#endif
