//
//  PlaybackSleepTimerButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackSleepTimerButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    var onMeshBackground: Bool = false

    private var isOpen: Bool {
        viewModel.activeCard == .sleepTimerPicker
    }

    private func remainingSleepTime(at date: Date) -> Double? {
        if let sleepTimer = satellite.sleepTimer, case .interval(let expiresAt, _) = sleepTimer {
            return date.distance(to: expiresAt)
        }

        return nil
    }

    private func accessibilityValue(at date: Date) -> String {
        if let remainingSleepTime = remainingSleepTime(at: date) {
            return remainingSleepTime.formatted(.duration)
        }

        if let sleepTimer = satellite.sleepTimer {
            switch sleepTimer {
                case .chapters(let amount, _):
                    return String(localized: "sleepTimer.chapter") + " \(amount)"
                default:
                    break
            }
        }

        return 0.formatted(.duration)
    }

    @ViewBuilder
    private func label(at date: Date) -> some View {
        ZStack {
            Group {
                Image(systemName: "append.page")
                Image(systemName: "moon.zzz.fill")
            }
            .hidden()

            if let sleepTimer = satellite.sleepTimer {
                switch sleepTimer {
                    case .chapters(_, _):
                        Label("sleepTimer.chapter", systemImage: "append.page")
                    case .interval(_, _):
                        let remainingSleepTime = remainingSleepTime(at: date)

                        if let remainingSleepTime {
                            Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                                .fontDesign(.rounded)
                                .contentTransition(.numericText())
                                .modify(if: viewModel.expansionAnimationCount == 0) {
                                    $0
                                        .animation(.smooth, value: remainingSleepTime)
                                }
                        } else {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
            } else {
                Label("playback.sleepTimer", systemImage: "moon.zzz.fill")
            }
        }
        .padding(12)
        .contentShape(.rect(cornerRadius: 4))
    }

    var body: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.activeCard = isOpen ? nil : .sleepTimerPicker
            }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                label(at: context.date)
                    .accessibilityValue(Text(accessibilityValue(at: context.date)))
            }
        }
        .hoverEffect(.highlight)
        .modify(if: isOpen) {
            $0.glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
        }
        .padding(-12)
        .accessibilityLabel("playback.sleepTimer")
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }
}

struct PlaybackSleepTimerPickerCard: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let onMeshBackground: Bool

    @State private var pendingMinutes: Double = 30
    @State private var dragAnchorMinutes: Double?
    @State private var dragTranslation: CGFloat = 0
    @State private var isDragging = false
    @State private var lastNearestPreset: Double?
    @State private var lastAppliedMinutes: Double = 0

    private let minMinutes: Double = 1
    private let maxMinutes: Double = 180
    private let step: Double = 1
    private let tickSpacing: CGFloat = 12

    private var presetMinutes: [Double] {
        AppSettings.shared.sleepTimerIntervals.map { $0 / 60 }
    }

    private var primaryColor: Color {
        onMeshBackground ? .white : .primary
    }

    private var secondaryColor: Color {
        onMeshBackground ? .white.opacity(0.6) : .secondary
    }

    private var activeInterval: (expiresAt: Date, extend: TimeInterval)? {
        if case .interval(let expiresAt, let extend) = satellite.sleepTimer {
            return (expiresAt, extend)
        }
        return nil
    }

    private var activeChapterAmount: Int? {
        if case .chapters(let amount, _) = satellite.sleepTimer {
            return amount
        }
        return nil
    }

    private var hasChapter: Bool { satellite.chapter != nil }
    private var isTimerActive: Bool { satellite.sleepTimer != nil }

    private var rulerAnchorMinutes: Double {
        if let interval = activeInterval {
            let remainingMinutes = interval.expiresAt.timeIntervalSinceNow / 60
            return max(minMinutes, min(maxMinutes, remainingMinutes))
        }
        return pendingMinutes
    }

    private var rulerDisplayMinutes: Double {
        guard isDragging, let anchor = dragAnchorMinutes else {
            return rulerAnchorMinutes
        }
        let delta = -dragTranslation / tickSpacing * step
        return max(minMinutes, min(maxMinutes, anchor + delta))
    }

    private func snappedMinutes(_ value: Double) -> Double {
        let clamped = max(minMinutes, min(maxMinutes, value))
        return (clamped / step).rounded() * step
    }

    private func applyMinutes(_ minutes: Double) {
        let snapped = snappedMinutes(minutes)
        pendingMinutes = snapped
        satellite.setSleepTimer(.interval(snapped * 60))
    }

    private func presetGlass(isSelected: Bool) -> Glass {
        let base: Glass = onMeshBackground ? .clear.interactive() : .regular.interactive()
        return isSelected ? base.tint(primaryColor.opacity(0.12)) : base
    }

    var body: some View {
        VStack(spacing: 0) {
            topControls
                .padding(.bottom, 8)

            Spacer(minLength: 8)

            display

            Spacer(minLength: 20)

            Group {
                if activeChapterAmount != nil {
                    chapterStepper
                } else {
                    ruler
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 84)

            Spacer(minLength: 16)

            presetButtons
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .fontDesign(.rounded)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("playback.sleepTimer")
        .accessibilityAction(.escape) {
            withAnimation(.snappy) {
                viewModel.activeCard = nil
            }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
        .onAppear {
            if let interval = activeInterval {
                pendingMinutes = snappedMinutes(interval.expiresAt.timeIntervalSinceNow / 60)
            }
        }
    }

    @ViewBuilder
    private var topControls: some View {
        ZStack {
            if isTimerActive {
                HStack(spacing: 8) {
                    Button {
                        satellite.setSleepTimer(nil)
                    } label: {
                        Label("playback.sleepTimer.cancel", systemImage: "xmark")
                            .labelStyle(.titleAndIcon)
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(primaryColor)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)

                    Button {
                        satellite.extendSleepTimer()
                    } label: {
                        Label("playback.sleepTimer.extend", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundStyle(primaryColor)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.scale(scale: 0.4, anchor: .top).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 34)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: isTimerActive)
    }

    private func durationFormat(for seconds: TimeInterval) -> DurationComponentsFormatter {
        if seconds >= 3600 {
            return .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3)
        } else {
            return .duration(unitsStyle: .positional, allowedUnits: [.minute, .second], maximumUnitCount: 2)
        }
    }

    @ViewBuilder
    private var display: some View {
        Group {
            if let amount = activeChapterAmount {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(amount, format: .number)
                        .font(.system(size: 96, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(amount)))

                    Text("sleepTimer.chapter")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(secondaryColor)
                }
            } else if let interval = activeInterval, !isDragging {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = max(0, interval.expiresAt.timeIntervalSince(context.date))
                    Text(remaining, format: durationFormat(for: remaining))
                        .font(.system(size: 72, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                }
            } else {
                let seconds = rulerAnchorMinutes * 60
                Text(seconds, format: durationFormat(for: seconds))
                    .font(.system(size: 72, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText(value: rulerAnchorMinutes))
            }
        }
        .scaleEffect(isDragging ? 1.05 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: rulerAnchorMinutes)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }

    @ViewBuilder
    private var ruler: some View {
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

                SleepTimerRulerCanvas(minutes: rulerDisplayMinutes,
                                      minMinutes: minMinutes,
                                      maxMinutes: maxMinutes,
                                      step: step,
                                      tickSpacing: tickSpacing,
                                      tickHeight: tickHeight,
                                      labelSpacing: labelSpacing,
                                      labelHeight: labelHeight,
                                      primaryColor: primaryColor,
                                      secondaryColor: secondaryColor)
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
                    .animation(isDragging ? nil : .spring(response: 0.45, dampingFraction: 0.85), value: rulerDisplayMinutes)
            }
            .frame(width: width, height: geo.size.height, alignment: .top)
            .contentShape(.rect)
            .hapticFeedback(.selection, trigger: lastAppliedMinutes)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragAnchorMinutes == nil {
                            dragAnchorMinutes = rulerAnchorMinutes
                            lastAppliedMinutes = rulerAnchorMinutes
                            isDragging = true
                        }
                        dragTranslation = value.translation.width

                        let delta = -value.translation.width / tickSpacing * step
                        let target = snappedMinutes(dragAnchorMinutes! + delta)

                        if abs(target - lastAppliedMinutes) > 0.001 {
                            lastAppliedMinutes = target
                            applyMinutes(target)
                        }
                    }
                    .onEnded { _ in
                        dragAnchorMinutes = nil
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isDragging = false
                            dragTranslation = 0
                        }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("playback.sleepTimer")
            .accessibilityValue(Text(rulerDisplayMinutes * 60, format: .duration(unitsStyle: .full, allowedUnits: [.hour, .minute])))
            .accessibilityAdjustableAction { direction in
                switch direction {
                    case .increment:
                        applyMinutes(snappedMinutes(rulerAnchorMinutes + step))
                    case .decrement:
                        applyMinutes(snappedMinutes(rulerAnchorMinutes - step))
                    @unknown default:
                        break
                }
            }
        }
    }

    @ViewBuilder
    private var chapterStepper: some View {
        HStack(spacing: 32) {
            Button {
                guard let amount = activeChapterAmount else { return }
                if amount > 1 {
                    satellite.setSleepTimer(.chapters(amount - 1))
                } else {
                    satellite.setSleepTimer(nil)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(primaryColor)
                    .frame(width: 56, height: 56)
                    .glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("action.decrease")

            Button {
                guard let amount = activeChapterAmount else { return }
                satellite.setSleepTimer(.chapters(amount + 1))
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(primaryColor)
                    .frame(width: 56, height: 56)
                    .glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("action.increase")
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var presetButtons: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if hasChapter {
                        let isSelected = activeChapterAmount != nil

                        Button {
                            satellite.setSleepTimer(.chapters(1))
                        } label: {
                            Label("playback.sleepTimer.chapter", systemImage: "append.page")
                                .labelStyle(.titleAndIcon)
                                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? primaryColor : secondaryColor)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .glassEffect(presetGlass(isSelected: isSelected), in: .capsule)
                                .scaleEffect(isSelected ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                        .id("__chapter__")
                    }

                    ForEach(presetMinutes, id: \.self) { minutes in
                        let isSelected = activeChapterAmount == nil
                            && isTimerActive
                            && abs(rulerAnchorMinutes - minutes) < 0.001

                        Button {
                            applyMinutes(minutes)
                        } label: {
                            Text(minutes * 60, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute]))
                                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? primaryColor : secondaryColor)
                                .lineLimit(1)
                                .fixedSize()
                                .frame(minWidth: 44)
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .glassEffect(presetGlass(isSelected: isSelected), in: .capsule)
                                .scaleEffect(isSelected ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                        .id(minutes)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .onAppear {
                if let nearest = nearestPreset {
                    lastNearestPreset = nearest
                    scrollProxy.scrollTo(nearest, anchor: .center)
                }
            }
            .onChange(of: rulerAnchorMinutes) { _, minutes in
                let nearest = presetMinutes.min(by: { abs($0 - minutes) < abs($1 - minutes) })
                guard let nearest, nearest != lastNearestPreset else { return }
                lastNearestPreset = nearest
                withAnimation(.smooth) {
                    scrollProxy.scrollTo(nearest, anchor: .center)
                }
            }
        }
        .frame(height: 48)
    }

    private var nearestPreset: Double? {
        presetMinutes.min(by: { abs($0 - rulerAnchorMinutes) < abs($1 - rulerAnchorMinutes) })
    }
}

private struct SleepTimerRulerCanvas: View, @preconcurrency Animatable {
    var minutes: Double
    let minMinutes: Double
    let maxMinutes: Double
    let step: Double
    let tickSpacing: CGFloat
    let tickHeight: CGFloat
    let labelSpacing: CGFloat
    let labelHeight: CGFloat
    let primaryColor: Color
    let secondaryColor: Color

    var animatableData: Double {
        get { minutes }
        set { minutes = newValue }
    }

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let centerX = size.width / 2
            let tickCount = Int(((maxMinutes - minMinutes) / step).rounded()) + 1
            let currentIndex = (minutes - minMinutes) / step
            let offsetX = centerX - CGFloat(currentIndex) * tickSpacing - tickSpacing / 2

            let majorHeight: CGFloat = 24
            let minorHeight: CGFloat = 10
            let labelY = tickHeight + labelSpacing + labelHeight / 2

            for index in 0..<tickCount {
                let tickX = offsetX + CGFloat(index) * tickSpacing + tickSpacing / 2
                if tickX < -8 || tickX > size.width + 8 { continue }

                let minuteValue = minMinutes + Double(index) * step
                let rounded = Int(minuteValue.rounded())
                let major = rounded % 5 == 0

                let height: CGFloat = major ? majorHeight : minorHeight
                let width: CGFloat = major ? 1.75 : 1
                let opacity: Double = major ? 0.9 : 0.3

                let barRect = CGRect(x: tickX - width / 2, y: tickHeight - height, width: width, height: height)
                context.fill(Path(barRect), with: .color(primaryColor.opacity(opacity)))

                if major && rounded % 15 == 0 {
                    let text = Text(verbatim: "\(rounded)")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(secondaryColor)
                    context.draw(text, at: CGPoint(x: tickX, y: labelY), anchor: .center)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PlaybackSleepTimerButton()
        .previewEnvironment()
}

#Preview {
    PlaybackSleepTimerPickerCard(onMeshBackground: false)
        .previewEnvironment()
}
#endif
