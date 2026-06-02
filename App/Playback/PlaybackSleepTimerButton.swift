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

    /// Captured "now" at the moment playback paused. The engine leaves `expiresAt`
    /// static while paused (it only shifts forward on resume), so a live `now`
    /// reference would make the displayed remaining shrink even though the timer
    /// is actually frozen. Using this snapshot freezes the display until playback
    /// resumes.
    @State private var pauseFreezeDate: Date?

    private var isOpen: Bool {
        viewModel.activeCard == .sleepTimerPicker
    }

    private var hasIntervalTimer: Bool {
        if case .interval = satellite.sleepTimer { return true }
        return false
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
                            sleepTimerLiveLabel(remaining: remainingSleepTime)
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
        .contentShape(.capsule)
    }

    var body: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.activeCard = isOpen ? nil : .sleepTimerPicker
            }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        } label: {
            if satellite.isPlaying && hasIntervalTimer {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    label(at: context.date)
                        .accessibilityValue(Text(accessibilityValue(at: context.date)))
                }
            } else {
                let frozen = pauseFreezeDate ?? .now
                label(at: frozen)
                    .accessibilityValue(Text(accessibilityValue(at: frozen)))
            }
        }
        .hoverEffect(.highlight)
        .modify(if: isOpen) {
            $0.glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
        }
        .padding(-12)
        .accessibilityLabel("playback.sleepTimer")
        .accessibilityAddTraits(isOpen ? .isSelected : [])
        .onChange(of: satellite.isPlaying, initial: true) { _, playing in
            pauseFreezeDate = playing ? nil : .now
        }
    }

    /// Sub-hour timers show the single largest unit ("59m" / "12s"), matching the
    /// abbreviated countdown style used everywhere else in the app. At one hour or
    /// more, the abbreviated single-unit format collapses to "60m" / "120m", which
    /// reads as broken — switch to a compact H:MM clock so the hour count is
    /// always visible at a glance.
    @ViewBuilder
    private func sleepTimerLiveLabel(remaining: TimeInterval) -> some View {
        if remaining >= 3600 {
            let totalMinutes = Int((remaining / 60).rounded())
            Text(verbatim: String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60))
        } else {
            Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
        }
    }
}

struct PlaybackSleepTimerPickerCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let onMeshBackground: Bool

    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    @State private var seconds: Int = 0
    @State private var chapterCount: Int = 1

    @State private var activeDragCount: Int = 0

    /// Mirrors the button's pause snapshot: while paused, `expiresAt` is static
    /// but wall-clock advances, so anything that computes "remaining" from
    /// `Date.now` would shrink the wheel value even though the actual timer is
    /// frozen. We freeze it at the moment playback paused instead.
    @State private var pauseFreezeDate: Date?

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

            // Equal-share spacers above and below the display center the timer in
            // the space between the top-controls strip and the presets.
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

            // On iPad (regular width) the presets pin to the bottom of the card;
            // on iPhone the trailing spacer keeps the block vertically centered.
            if horizontalSizeClass != .regular {
                Spacer(minLength: 12)
            }
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
        .onChange(of: satellite.isPlaying, initial: true) { _, playing in
            pauseFreezeDate = playing ? nil : .now
            // Re-seed so the wheel snaps to the frozen remaining on pause, and
            // back to the live (engine-shifted) remaining on resume.
            guard !isCardDragging else { return }
            seedFromExternalState()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Skip the per-second sync while paused: the engine freezes `expiresAt`
            // and the wheel already holds the correct value from the pause-time
            // seed, so there is nothing to advance.
            guard satellite.isPlaying, !isCardDragging else { return }
            // Animate the per-second tick so the seconds wheel glides between values
            // instead of snapping. The 0.45s spring response is shorter than the 1Hz
            // tick rate, so the wheel always settles before the next update.
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                syncFromCountdown()
            }
        }
    }

    /// Single, large H:MM:SS display used for both the live countdown ("active") and the
    /// drag-to-set picker ("inactive"). Mirrors the iOS Clock "New Alarm" picker: one
    /// continuous rounded rectangle spans the selected row across all three columns and
    /// the colon separators, instead of three per-column rings.
    @ViewBuilder
    private var unifiedTimerDisplay: some View {
        let columnRowHeight: CGFloat = 40
        let columnFontSize: CGFloat = 32
        // Match the digit font size so the colons share the same baseline metrics —
        // a smaller separator font shifts ":" off the digits' visual midline.
        let separatorFontSize: CGFloat = 32

        ZStack {
            selectionRowBackground(height: columnRowHeight)

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
                    showsRing: false
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
                    showsRing: false,
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
                    showsRing: false,
                    isInteractive: false,
                    displayWidth: 2
                )
                .frame(maxWidth: .infinity)
                // The seconds wheel is read-only — dim it so it reads as
                // "display, not input" next to the interactive H/M columns.
                .opacity(0.5)
            }
        }
        .padding(.horizontal, 8)
    }

    /// Single continuous rounded rectangle behind the wheel's center row.
    /// Replaces the per-column rings to match the iOS system-picker look,
    /// where the selection slot reads as one bar across the full row.
    @ViewBuilder
    private func selectionRowBackground(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(primaryColor.opacity(0.10))
            .frame(height: height)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var chapterPicker: some View {
        let columnRowHeight: CGFloat = 40
        let columnFontSize: CGFloat = 32

        ZStack {
            selectionRowBackground(height: columnRowHeight)

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
                    showsRing: false
                )
                .frame(width: 80)

                Text("sleepTimer.chapter")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(secondaryColor)
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var topControls: some View {
        GlassEffectContainer {
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
                            .contentShape(.capsule)
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
                            .contentShape(.capsule)
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
        GlassEffectContainer {
            VStack(spacing: 8) {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .glassEffect(presetGlass(isSelected: isSelected), in: .capsule)
                            .contentShape(.capsule)
                            .scaleEffect(isSelected ? 1.04 : 1)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                }
                
                // Chunked HStack rows instead of LazyVGrid — lazy grids recycle
                // children as they scroll in and out of the viewport, which kills the
                // selection / scale / glass-effect animations on the chips.
                let columns = 5
                let rows = stride(from: 0, to: presetMinutes.count, by: columns).map {
                    Array(presetMinutes[$0..<min($0 + columns, presetMinutes.count)])
                }
                
                VStack(spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { minutes in
                                presetChip(minutes: minutes)
                            }
                            // Pad short rows with invisible cells so every chip
                            // keeps its column width — without this the last
                            // row's chips would stretch to fill the row.
                            if row.count < columns {
                                ForEach(0..<(columns - row.count), id: \.self) { _ in
                                    Color.clear
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func presetChip(minutes: Double) -> some View {
        let isSelected = activeChapterAmount == nil
        && isTimerActive
        && abs(Double(totalMinutes) - minutes) < 0.001
        
        Button {
            applyPresetMinutes(minutes)
        } label: {
            presetChipLabel(minutes: minutes)
                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                .monospacedDigit()
                .foregroundStyle(isSelected ? primaryColor : secondaryColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .glassEffect(presetGlass(isSelected: isSelected), in: .capsule)
                .contentShape(.capsule)
                .scaleEffect(isSelected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .animation(isCardDragging ? nil : .spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
    }
    
    /// Anything one hour or longer renders as "H:MM" so a long preset (e.g. 90 min,
    /// 120 min) shows as "1:30" / "2:00" instead of "1 hr 30 min" / "2 hr". Sub-hour
    /// presets keep the localized short unit format ("30 min").
    @ViewBuilder
    private func presetChipLabel(minutes: Double) -> some View {
        let total = Int(minutes)
        if total >= 60 {
            Text(verbatim: String(format: "%d:%02d", total / 60, total % 60))
        } else {
            Text(minutes * 60, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute]))
        }
    }
    
    private func startDrag() {
        activeDragCount += 1
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
                let reference = satellite.isPlaying ? Date.now : (pauseFreezeDate ?? .now)
                let remaining = max(0, reference.distance(to: expiresAt))
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
