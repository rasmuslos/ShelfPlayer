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

    @State private var hours: Int = 0
    @State private var minutesTens: Int = 3
    @State private var minutesOnes: Int = 0

    @State private var activeDragCount: Int = 0
    @State private var lastNearestPreset: Double?

    private var isCardDragging: Bool { activeDragCount > 0 }

    private var totalMinutes: Int {
        hours * 60 + minutesTens * 10 + minutesOnes
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(totalMinutes * 60)
    }

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
                    timeColumns
                }
            }
            .frame(maxWidth: .infinity)

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
            seedFromExternalState()
        }
        .onChange(of: satellite.sleepTimer) { _, _ in
            guard !isCardDragging else { return }
            seedFromExternalState()
        }
    }

    @ViewBuilder
    private var timeColumns: some View {
        HStack(alignment: .center, spacing: 8) {
            VerticalDigitColumn(
                value: $hours,
                range: 0...9,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.hours",
                onDragStart: startDrag,
                onCommit: { _ in endDrag() }
            )
            .frame(maxWidth: .infinity)

            Text(verbatim: ":")
                .font(.system(.title, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(primaryColor.opacity(0.6))
                .accessibilityHidden(true)

            VerticalDigitColumn(
                value: $minutesTens,
                range: 0...6,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.minutes.tens",
                onDragStart: startDrag,
                onCommit: { _ in endDrag() }
            )
            .frame(maxWidth: .infinity)

            VerticalDigitColumn(
                value: $minutesOnes,
                range: 0...9,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.minutes.ones",
                disabledValues: minutesTens == 6 ? Set(1...9) : [],
                onDragStart: startDrag,
                onCommit: { _ in endDrag() }
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .onChange(of: minutesTens) { _, tens in
            if tens == 6, minutesOnes != 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    minutesOnes = 0
                }
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
            } else if let interval = activeInterval, !isCardDragging {
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
                let seconds = totalSeconds
                Text(seconds, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute], maximumUnitCount: 2))
                    .font(.system(size: 72, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .modify(if: !isCardDragging) {
                        $0.contentTransition(.numericText(value: Double(totalMinutes)))
                    }
            }
        }
        .scaleEffect(isCardDragging ? 1.05 : 1)
        .animation(isCardDragging ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: totalMinutes)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCardDragging)
        .accessibilityHidden(true)
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
                            && abs(Double(totalMinutes) - minutes) < 0.001

                        Button {
                            applyPresetMinutes(minutes)
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
                        .animation(isCardDragging ? nil : .spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
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
            .onChange(of: totalMinutes) { _, _ in
                guard !isCardDragging else { return }
                scrollToNearest(using: scrollProxy)
            }
            .onChange(of: isCardDragging) { _, dragging in
                guard !dragging else { return }
                scrollToNearest(using: scrollProxy)
            }
        }
        .frame(height: 48)
    }

    private var nearestPreset: Double? {
        presetMinutes.min(by: { abs($0 - Double(totalMinutes)) < abs($1 - Double(totalMinutes)) })
    }

    private func scrollToNearest(using scrollProxy: ScrollViewProxy) {
        guard let nearest = nearestPreset, nearest != lastNearestPreset else { return }
        lastNearestPreset = nearest
        withAnimation(.smooth) {
            scrollProxy.scrollTo(nearest, anchor: .center)
        }
    }

    private func startDrag() {
        activeDragCount += 1
        viewModel.isCardSliderInUse = true
    }

    private func endDrag() {
        activeDragCount = max(0, activeDragCount - 1)
        guard activeDragCount == 0 else { return }
        viewModel.isCardSliderInUse = false
        commitTime()
    }

    private func commitTime() {
        let total = totalMinutes
        guard total > 0 else { return }
        satellite.setSleepTimer(.interval(TimeInterval(total * 60)))
    }

    private func applyPresetMinutes(_ minutes: Double) {
        decompose(totalMinutes: minutes)
        satellite.setSleepTimer(.interval(minutes * 60))
    }

    private func decompose(totalMinutes: Double) {
        let m = max(0, Int(totalMinutes.rounded()))
        hours = min(9, m / 60)
        let rem = min(59, m % 60)
        minutesTens = rem / 10
        minutesOnes = rem % 10
    }

    private func seedFromExternalState() {
        if case .interval(let expiresAt, _) = satellite.sleepTimer {
            let remainingMinutes = max(0, expiresAt.timeIntervalSinceNow) / 60
            decompose(totalMinutes: remainingMinutes)
        }
    }
}

#if DEBUG
#Preview("Sleep-timer button") {
    PlaybackSleepTimerButton()
        .previewEnvironment()
}

#Preview("Sleep-timer button on mesh") {
    ZStack {
        LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        PlaybackSleepTimerButton(onMeshBackground: true)
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
    .previewEnvironment()
}

#Preview("Sleep-timer card") {
    PlaybackSleepTimerPickerCard(onMeshBackground: false)
        .previewEnvironment()
}

#Preview("Sleep-timer card on mesh") {
    ZStack {
        LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        PlaybackSleepTimerPickerCard(onMeshBackground: true)
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
    .previewEnvironment()
}
#endif
