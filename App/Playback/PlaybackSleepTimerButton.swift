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
    @State private var minutes: Int = 30
    @State private var seconds: Int = 0
    @State private var chapterCount: Int = 1

    @State private var activeDragCount: Int = 0
    @State private var lastNearestPreset: Double?

    private var isCardDragging: Bool { activeDragCount > 0 }

    private var totalSeconds: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    /// Whole-minute representation used by the preset chips and their auto-centering
    /// scroll. Rounded up so the chip the user just tapped stays highlighted until the
    /// next whole minute elapses, instead of going stale 1 second after selection.
    private var totalMinutes: Int {
        Int((totalSeconds / 60).rounded(.up))
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

            // Equal-share spacers above and below the display so the timer sits at
            // the geometric center of the card rather than being pulled toward the
            // shorter top-controls strip.
            Spacer(minLength: 12)

            if activeChapterAmount != nil {
                chapterPicker
                    .frame(maxWidth: .infinity)
            } else {
                unifiedTimerDisplay
                    .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 12)

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
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Animate the per-second tick so the seconds wheel glides between values
            // instead of snapping. The 0.45s spring response is shorter than the 1Hz
            // tick rate, so the wheel always settles before the next update.
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                syncFromCountdown()
            }
        }
    }

    /// Single, large H:MM display used for both the live countdown ("active") and the
    /// drag-to-set picker ("inactive"). The two states render identically — same fonts,
    /// same wheel layout, same neighbor digits — except the inactive state draws the
    /// rounded "rings" behind the selected row to read as an input affordance.
    @ViewBuilder
    private var unifiedTimerDisplay: some View {
        let showsRing = !isTimerActive || isCardDragging
        let columnRowHeight: CGFloat = 40
        let columnFontSize: CGFloat = 32
        // Match the digit font size so the colons share the same baseline metrics —
        // a smaller separator font shifts ":" off the digits' visual midline.
        let separatorFontSize: CGFloat = 32

        HStack(alignment: .center, spacing: 2) {
            VerticalDigitColumn(
                value: $hours,
                range: 0...9,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.hours",
                onDragStart: handleColumnDragStart,
                onCommit: { _ in endDrag() },
                rowHeight: columnRowHeight,
                visibleRows: 5,
                fontSize: columnFontSize,
                showsRing: showsRing
            )
            .frame(maxWidth: .infinity)

            Text(verbatim: ":")
                .font(.system(size: separatorFontSize, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(primaryColor.opacity(0.6))
                .padding(.horizontal, 4)
                .accessibilityHidden(true)

            VerticalDigitColumn(
                value: $minutes,
                range: 0...59,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.minutes",
                onDragStart: handleColumnDragStart,
                onCommit: { _ in endDrag() },
                rowHeight: columnRowHeight,
                visibleRows: 5,
                fontSize: columnFontSize,
                showsRing: showsRing,
                displayWidth: 2
            )
            .frame(maxWidth: .infinity)

            Text(verbatim: ":")
                .font(.system(size: separatorFontSize, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(primaryColor.opacity(0.6))
                .padding(.horizontal, 4)
                .accessibilityHidden(true)

            // Seconds wheel is read-only — it mirrors the live countdown but the user
            // sets the sleep timer to whole-minute precision via the H/M columns or a
            // preset chip. `isInteractive: false` strips the drag & adjustable action so
            // this column is purely a display element.
            VerticalDigitColumn(
                value: $seconds,
                range: 0...59,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.sleepTimer.seconds",
                rowHeight: columnRowHeight,
                visibleRows: 5,
                fontSize: columnFontSize,
                showsRing: showsRing,
                isInteractive: false,
                displayWidth: 2
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var chapterPicker: some View {
        let columnRowHeight: CGFloat = 40
        let columnFontSize: CGFloat = 32

        HStack(alignment: .center, spacing: 16) {
            VerticalDigitColumn(
                value: $chapterCount,
                range: 1...99,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "sleepTimer.chapter",
                onDragStart: handleChapterDragStart,
                onCommit: { _ in endDrag() },
                rowHeight: columnRowHeight,
                visibleRows: 5,
                fontSize: columnFontSize,
                showsRing: true
            )
            .frame(width: 80)

            Text("sleepTimer.chapter")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(secondaryColor)
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

    /// Drag-start hook for the unified timer columns. When a live interval is running,
    /// snap our manual state to the countdown's current value *first*, then mark the card
    /// as dragging and cancel the timer. The order matters: the child column has already
    /// captured `dragAnchor = Double(value)` and we must not change `value` out from
    /// under it. By syncing while the binding still reads from the live countdown (which
    /// hands back the same value the anchor was just set to), then setting the drag flag
    /// (which freezes the countdown sync) and finally clearing the timer, the in-flight
    /// drag keeps its momentum and just continues against manual state.
    ///
    /// Finally clear the seconds wheel: once the user touches the timer they're in
    /// whole-minute input mode (the seconds column isn't even interactive), so any
    /// leftover seconds from the live countdown would otherwise survive into `commitTime`
    /// and the new timer would inherit an arbitrary 0–59 second offset.
    private func handleColumnDragStart() {
        if activeInterval != nil {
            syncFromCountdown(force: true)
        }
        startDrag()
        if activeInterval != nil {
            satellite.setSleepTimer(nil)
        }
        if seconds != 0 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                seconds = 0
            }
        }
    }

    /// Pulls the live countdown's remaining time into the wheel state. Called once per
    /// second while a timer is active and the card is not being dragged; the wheels then
    /// animate to the new digit positions via their built-in spring. Rounded up so the
    /// final second reads "1" for a full beat before the timer ends, the way Apple's
    /// own timers behave.
    private func syncFromCountdown(force: Bool = false) {
        guard let interval = activeInterval else { return }
        if !force && isCardDragging { return }
        let totalSec = max(0, Int(interval.expiresAt.timeIntervalSinceNow.rounded(.up)))
        applyTotalSeconds(totalSec)
    }

    private func endDrag() {
        activeDragCount = max(0, activeDragCount - 1)
        guard activeDragCount == 0 else { return }
        viewModel.isCardSliderInUse = false
        if activeChapterAmount != nil {
            commitChapter()
        } else {
            commitTime()
        }
    }

    private func commitTime() {
        let total = totalSeconds
        guard total > 0 else { return }
        satellite.setSleepTimer(.interval(total))
    }

    private func commitChapter() {
        let amount = max(1, chapterCount)
        satellite.setSleepTimer(.chapters(amount))
    }

    /// Chapter wheel only mounts while a chapter timer is already active, so unlike the
    /// time wheels we don't need to cancel an in-flight interval or zero out neighbor
    /// columns — just mark the card as dragging so the live-state sync stays paused.
    private func handleChapterDragStart() {
        startDrag()
    }

    private func applyPresetMinutes(_ minutes: Double) {
        decompose(totalMinutes: minutes)
        satellite.setSleepTimer(.interval(minutes * 60))
    }

    /// Decomposes a whole-minute count (used by presets and the legacy seed path) into
    /// the three wheels. Seconds always reset to zero — presets are minute-granular and
    /// any leftover seconds from a previous countdown should clear when the user picks
    /// a fresh duration.
    private func decompose(totalMinutes: Double) {
        let m = max(0, Int(totalMinutes.rounded()))
        applyTotalSeconds(m * 60)
    }

    private func applyTotalSeconds(_ total: Int) {
        let clamped = max(0, total)
        let newHours = min(9, clamped / 3600)
        let afterHours = min(3599, clamped % 3600)
        let newMinutes = afterHours / 60
        let newSeconds = afterHours % 60
        if hours != newHours { hours = newHours }
        if minutes != newMinutes { minutes = newMinutes }
        if seconds != newSeconds { seconds = newSeconds }
    }

    private func seedFromExternalState() {
        switch satellite.sleepTimer {
            case .interval(let expiresAt, _):
                let remaining = max(0, expiresAt.timeIntervalSinceNow)
                applyTotalSeconds(Int(remaining.rounded(.up)))
            case .chapters(let amount, _):
                chapterCount = max(1, amount)
            case nil:
                break
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

#Preview("Sleep-timer card (chapter)") {
    PlaybackSleepTimerPickerCard(onMeshBackground: false)
        .previewEnvironment(sleepTimer: .chapters(3))
}

#Preview("Sleep-timer card (chapter) on mesh") {
    ZStack {
        LinearGradient(colors: [.indigo, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        PlaybackSleepTimerPickerCard(onMeshBackground: true)
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
    .previewEnvironment(sleepTimer: .chapters(3))
}
#endif
