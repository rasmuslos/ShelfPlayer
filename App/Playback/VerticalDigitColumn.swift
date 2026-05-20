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

    /// Vertical pitch of each row and the visible height of the bold center row.
    var rowHeight: CGFloat = 36
    /// Number of rows rendered around the center; the top/bottom are softly masked so
    /// only the center plus a hint of neighbors reads clearly.
    var visibleRows: Int = 5
    /// Point size of the digit text. Driven separately from `rowHeight` so callers can
    /// tune the bold-row visual weight independently of the wheel pitch.
    var fontSize: CGFloat = 22
    /// Whether to draw the rounded background "ring" around the selected row. When
    /// `false`, the column draws no center-row affordance at all — the parent is
    /// expected to render a single continuous selection rectangle that spans the
    /// row across multiple columns.
    var showsRing: Bool = true
    /// When false the column ignores drag/adjustable input — it's a read-only display.
    /// The sleep-timer card uses this for the seconds wheels, which only mirror the
    /// live countdown and aren't part of the user-set value.
    var isInteractive: Bool = true
    /// Minimum digit count for the rendered value, zero-padded. Use 2 for mm/ss-style
    /// columns that should display "00"–"59".
    var displayWidth: Int = 1

    @State private var dragAnchor: Double?
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging = false
    /// Monotonic counter incremented only when a user drag snaps to a new digit. We
    /// fire haptics off this instead of `snappedValue` so external value changes (e.g.
    /// the live sleep-timer countdown driving the column) don't fire haptics per tick.
    @State private var hapticTick: Int = 0
    /// Offset in points used to glide the canvas from the finger's release position
    /// into the snapped slot. The `.animation(value: smoothPosition)` modifier alone
    /// can't drive that animation reliably — by the time `dragAnchor` clears and the
    /// computed `smoothPosition` jumps, the modifier still reads `isDragging == true`
    /// on that render and picks the no-animation branch. Routing the snap through a
    /// dedicated `withAnimation`-driven offset sidesteps that race entirely.
    @State private var landingOffset: CGFloat = 0

    private var enabledBounds: ClosedRange<Int> {
        let enabled = range.filter { !disabledValues.contains($0) }
        guard let lo = enabled.min(), let hi = enabled.max() else { return value...value }
        return lo...hi
    }

    private var smoothPosition: Double {
        if let anchor = dragAnchor {
            let delta = -dragTranslation / rowHeight
            return clamp(anchor + delta)
        }
        // Idle path: anchored on the integer value, with any in-flight landing offset
        // pulling the canvas back to where the finger released. When the spring settles
        // to landingOffset == 0 the position equals Double(value) exactly.
        return Double(value) + (-landingOffset / rowHeight)
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
        let ringRadius = min(16, rowHeight * 0.22)
        // Read-only columns never get the soft fill (no input to advertise).
        let fillOpacity: Double = isInteractive ? 0.08 : 0
        let strokeOpacity: Double = 0.22

        ZStack {
            if showsRing {
                RoundedRectangle(cornerRadius: ringRadius, style: .continuous)
                    .fill(primaryColor.opacity(fillOpacity))
                    .frame(height: rowHeight)

                RoundedRectangle(cornerRadius: ringRadius, style: .continuous)
                    .strokeBorder(primaryColor.opacity(strokeOpacity), lineWidth: 1)
                    .frame(height: rowHeight)
            }

            DigitCanvas(
                smoothPosition: smoothPosition,
                rangeLower: range.lowerBound,
                rangeUpper: range.upperBound,
                rowHeight: rowHeight,
                fontSize: fontSize,
                primaryColor: primaryColor,
                disabledValues: disabledValues,
                displayWidth: displayWidth
            )
            .frame(height: height)
            .mask(
                // Fade only the half-row that hangs off each edge so 2 preview digits
                // stay readable above and below the center. The opaque zone covers all
                // row centers while the gradient soft-fades just the outer halves of
                // the topmost and bottommost rows.
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: max(0.04, 0.5 / Double(visibleRows))),
                    .init(color: .black, location: min(0.96, 1 - 0.5 / Double(visibleRows))),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            )
            .animation(isDragging ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: smoothPosition)
        }
        .frame(height: height)
        .contentShape(.rect)
        .hapticFeedback(.selection, trigger: hapticTick)
        .modify(if: isInteractive) {
            $0.gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragAnchor == nil {
                            dragAnchor = Double(value)
                            isDragging = true
                            // Cancel any in-flight landing animation. We snap to the
                            // current value as the new anchor — if the user re-grabs
                            // mid-settle they pick up from the slot, not from the
                            // animation's current frame.
                            landingOffset = 0
                            onDragStart()
                        }
                        dragTranslation = g.translation.height

                        let snapped = snappedValue
                        if value != snapped {
                            value = snapped
                            hapticTick &+= 1
                        }
                    }
                    .onEnded { g in
                        // Capture the on-screen position the finger released at so the
                        // hand-off from the drag formula to the idle formula doesn't
                        // visually jump.
                        let releaseSmooth = smoothPosition

                        // Project where the wheel should settle using SwiftUI's
                        // velocity-aware predicted end. Without this, a short fast
                        // flick only moves the wheel by the small finger-travel
                        // distance — there's no momentum and the wheel feels dead.
                        // The predicted overshoot is dampened because SwiftUI's
                        // projection tends to overshoot what reads naturally for a
                        // chip-sized wheel.
                        let anchor = dragAnchor ?? Double(value)
                        let momentum = (g.predictedEndTranslation.height - g.translation.height) * 0.6
                        let projectedTranslation = g.translation.height + momentum
                        let projectedSmooth = clamp(anchor + (-projectedTranslation / rowHeight))
                        let final = nearestEnabled(to: Int(projectedSmooth.rounded()))

                        onCommit(final)

                        // Pick the landing offset that keeps smoothPosition unchanged at
                        // the switchover instant: Double(final) + (-offset / rowHeight)
                        // = releaseSmooth  =>  offset = -(releaseSmooth - Double(final)) * rowHeight.
                        let initialLanding = -CGFloat(releaseSmooth - Double(final)) * rowHeight

                        dragAnchor = nil
                        dragTranslation = 0
                        if value != final {
                            value = final
                            hapticTick &+= 1
                        }
                        landingOffset = initialLanding
                        isDragging = false

                        // Spring the offset to zero — this glides smoothPosition the
                        // last fractional step into Double(final) without depending on
                        // the .animation(value: smoothPosition) modifier seeing the
                        // right isDragging state at the right moment.
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            landingOffset = 0
                        }
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(Text(verbatim: "\(value)"))
        .modify(if: isInteractive) {
            $0.accessibilityAdjustableAction { direction in
                switch direction {
                    case .increment:
                        let next = nextEnabled(after: value, ascending: true)
                        value = next
                        hapticTick &+= 1
                        onCommit(next)
                    case .decrement:
                        let next = nextEnabled(after: value, ascending: false)
                        value = next
                        hapticTick &+= 1
                        onCommit(next)
                    @unknown default:
                        break
                }
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
    let fontSize: CGFloat
    let primaryColor: Color
    let disabledValues: Set<Int>
    let displayWidth: Int

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

                let formatted = displayWidth > 1
                    ? String(format: "%0\(displayWidth)d", v)
                    : "\(v)"
                let text = Text(verbatim: formatted)
                    .font(.system(size: fontSize, weight: weight))
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
    @State private var minutes: Int = 30
    var onMeshBackground: Bool = false

    private var primary: Color { onMeshBackground ? .white : .primary }
    private var secondary: Color { onMeshBackground ? .white.opacity(0.6) : .secondary }

    private var totalMinutes: Int { hours * 60 + minutes }

    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: String(format: "%d:%02d", hours, minutes))
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
                    value: $minutes,
                    range: 0...59,
                    primaryColor: primary,
                    secondaryColor: secondary,
                    accessibilityLabel: "Minutes",
                    displayWidth: 2
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
