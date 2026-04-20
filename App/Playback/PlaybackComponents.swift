//
//  PlaybackComponents.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import AVKit
import ShelfPlayback

struct PlaybackTitle: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let showTertiarySupplements: Bool

    @State private var uuid = UUID()
    @State private var marqueeController = MarqueeController()

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                PlaybackMenuActions()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if let currentItem = satellite.nowPlayingItem {
                        if showTertiarySupplements, let episode = currentItem as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                                .font(.subheadline.smallCaps())
                                .foregroundStyle(.tertiary)
                        }

                        MarqueeText(text: currentItem.name, font: .headline, controller: marqueeController)
                            .id(currentItem.name)

                        MarqueeText(text: currentItem.authors.formatted(.list(type: .and, width: .short)), font: .subheadline, foregroundStyle: .init(.secondary), controller: marqueeController)
                            .id(currentItem.authors)
                    } else {
                        Text("loading")
                            .font(.headline)
                    }
                }
                .id((satellite.nowPlayingItem?.sortName ?? "ijwefnoijoiujoizg") + "_nowPlaying_text_title_\(uuid)")
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if satellite.nowPlayingItemID?.type == .audiobook {
                Spacer(minLength: 12)

                if viewModel.isCreatingBookmark {
                    ProgressView()
                } else {
                    Label("playback.alert.createBookmark", systemImage: "bookmark")
                        .labelStyle(.iconOnly)
                        .padding(4)
                        .contentShape(.rect)
                        .onTapGesture {
                            viewModel.presentCreateBookmarkAlert()
                        }
                        .onLongPressGesture {
                            viewModel.createQuickBookmark()
                        }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

struct PlaybackBackwardButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    @State private var seekTimer: Timer?

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Label("playback.skip.backward", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
            .labelStyle(.iconOnly)
            .foregroundStyle(isLoading ? .secondary : .primary)
            .padding(12)
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.5, perform: {}, onPressingChanged: { pressing in
                if pressing {
                    skipController.skipPressed(forwards: false, satellite: satellite)
                    seekTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { [satellite, skipController] _ in
                        Task { @MainActor in
                            skipController.skipPressed(forwards: false, satellite: satellite)
                        }
                    }
                } else {
                    seekTimer?.invalidate()
                    seekTimer = nil
                }
            })
            .padding(-12)
            .disabled(isLoading)
            .symbolEffect(.rotate.counterClockwise.byLayer, options: .speed(10), value: skipController.notifySkipBackwards)
            .animation(.smooth, value: isLoading)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Text(verbatim: "\(viewModel.skipBackwardsInterval)"))
    }
}
struct PlaybackForwardButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    @State private var seekTimer: Timer?

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Label("playback.skip.forward", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
            .labelStyle(.iconOnly)
            .foregroundStyle(isLoading ? .secondary : .primary)
            .padding(12)
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.5, perform: {}, onPressingChanged: { pressing in
                if pressing {
                    skipController.skipPressed(forwards: true, satellite: satellite)
                    seekTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { [satellite, skipController] _ in
                        Task { @MainActor in
                            skipController.skipPressed(forwards: true, satellite: satellite)
                        }
                    }
                } else {
                    seekTimer?.invalidate()
                    seekTimer = nil
                }
            })
            .padding(-12)
            .disabled(isLoading)
            .symbolEffect(.rotate.clockwise.byLayer, options: .speed(10), value: skipController.notifySkipForwards)
            .animation(.smooth, value: isLoading)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Text(verbatim: "\(viewModel.skipForwardsInterval)"))
    }
}

struct PlaybackTogglePlayButton: View {
    @Environment(Satellite.self) private var satellite

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Button(satellite.isPlaying ? "playback.pause" : "playback.play", systemImage: satellite.isPlaying ? "pause" : "play") {
            satellite.togglePlaying()
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .imageScale(.large)
        .symbolVariant(.fill)
        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
        .opacity(isLoading ? 0 : 1)
        .overlay {
            if isLoading {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, isActive: isLoading)
            }
        }
        .accessibilityRemoveTraits(.isImage)
        .id(satellite.nowPlayingItemID)
    }
}
struct PlaybackSmallTogglePlayButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        ZStack {
            Group {
                Image(systemName: "play.fill")
                Image(systemName: "pause.fill")
            }
            .hidden()

            Group {
                if let currentItemID = satellite.nowPlayingItemID, satellite.isLoading(observing: currentItemID) {
                    ProgressView()
                } else if satellite.isBuffering || satellite.nowPlayingItemID == nil {
                    ProgressView()
                } else {
                    Button {
                        satellite.togglePlaying()
                    } label: {
                        Label(satellite.isPlaying ? "playback.pause" : "playback.play", systemImage: satellite.isPlaying ? "pause.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            .animation(.spring(duration: 0.2, bounce: 0.7), value: satellite.isPlaying)
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.blurReplace)
        }
    }
}

struct PlaybackControls: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    private var currentTime: TimeInterval {
        if let seeking = viewModel.seeking {
            satellite.chapterDuration * seeking
        } else {
            satellite.currentChapterTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seeking != nil {
            satellite.chapterDuration - currentTime
        } else {
            satellite.chapterDuration
        }
    }

    private var remaining: TimeInterval {
        if viewModel.seeking != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.chapterDuration - satellite.currentChapterTime) * (1 / satellite.playbackRate)
        }
    }

    private var aspectRatio: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            2.8
        } else {
            2
        }
    }

    @ViewBuilder
    private func skipText(forwards: Bool) -> some View {
        if let skipCache = skipController.skipCache {
            if (Double(-viewModel.skipBackwardsInterval) > skipCache && !forwards) || (Double(viewModel.skipForwardsInterval) < skipCache && forwards) {
                Text(abs(skipCache) ,format: .duration(unitsStyle: .positional, allowedUnits: [.second, .minute], maximumUnitCount: 2))
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .contentTransition(.numericText(value: skipCache))
                    .foregroundStyle(.secondary)
                    .animation(.snappy, value: skipCache)
            }
        }
    }

    @ViewBuilder
    private var backwardButton: some View {
        HStack(spacing: 0) {
            skipText(forwards: false)

            Spacer(minLength: 12)

            PlaybackBackwardButton()
        }
    }
    @ViewBuilder
    private var forwardButton: some View {
        HStack(spacing: 0) {
            PlaybackForwardButton()

            Spacer(minLength: 12)

            skipText(forwards: true)
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            PlaybackSlider(percentage: satellite.played, seeking: $viewModel.seeking, currentTime: currentTime, duration: duration, textFirst: false) {
                if let chapter = satellite.chapter, viewModel.seeking == nil {
                    Text(chapter.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                        .contentTransition(.numericText())
                        .animation(.smooth, value: remaining)
                }
            } complete: {
                satellite.seek(to: satellite.chapterDuration * $0, insideChapter: true) {
                    Task { @MainActor in
                        viewModel.seeking = nil
                    }
                }
            }

            Spacer(minLength: 8)

            LazyVGrid(columns: [.init(alignment: .trailing), .init(alignment: .center), .init(alignment: .leading)]) {
                backwardButton
                    .font(.title)

                PlaybackTogglePlayButton()
                    .font(.largeTitle)

                forwardButton
                    .font(.title)
            }
            Spacer(minLength: 8)

            BottomSlider()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .compositingGroup()
        .drawingGroup()
    }
}

struct PlaybackMenuActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    var body: some View {
        if let currentItem = satellite.nowPlayingItem {
            ControlGroup {
                ProgressButton(itemID: currentItem.id)
                StopPlaybackButton()

                ItemCollectionMembershipEditButton(itemID: currentItem.id)
            }

            if let audiobook = currentItem as? Audiobook {
                ItemLoadLink(itemID: audiobook.id)
                ItemMenu(authors: viewModel.authorIDs)
                ItemMenu(narrators: viewModel.narratorIDs)
                ItemMenu(series: viewModel.seriesIDs)
            } else if let episode = currentItem as? Episode {
                ItemLoadLink(itemID: episode.id)
                ItemLoadLink(itemID: episode.podcastID)
            }

            if let collection = satellite.upNextOrigin as? ItemCollection {
                ItemLoadLink(itemID: collection.id, footer: collection.name)
            }
        }
    }
}

struct PlaybackRateButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @State private var showPicker = false

    var body: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.isQueueVisible = false
                showPicker.toggle()
            }
        } label: {
            HStack(spacing: 0) {
                Text(satellite.playbackRate, format: .playbackRate.hideX())
                Image(decorative: "xsign")
                    .bold()
                    .padding(.horizontal, -3)
            }
            .padding(12)
            .contentTransition(.numericText())
            .contentShape(.rect(cornerRadius: 4))
            .modify(if: viewModel.expansionAnimationCount == 0) {
                $0
                    .animation(.smooth, value: satellite.playbackRate)
            }
        }
        .hoverEffect(.highlight)
        .padding(-12)
        .accessibilityLabel("preferences.playbackRate")
        .accessibilityValue(Text(satellite.playbackRate.formatted(.playbackRate)))
        .onChange(of: showPicker) {
            withAnimation(.snappy) {
                viewModel.isRatePickerVisible = showPicker
            }
        }
        .onChange(of: viewModel.isRatePickerVisible) {
            showPicker = viewModel.isRatePickerVisible
        }
    }
}

struct PlaybackRatePickerCard: View {
    @Environment(Satellite.self) private var satellite
    @Binding var isPresented: Bool

    private let presets: [Double] = AppSettings.shared.playbackRates
    private let barCount = 25
    private let minRate: Double = 0.5
    private let maxRate: Double = 2.5

    private func formatRate(_ rate: Double) -> String {
        if rate == 1.0 { return "1x" }
        if rate == floor(rate) { return "\(Int(rate))" }

        let formatted = String(format: "%.1f", rate)
        // Remove trailing zero for clean display like "1,3" instead of "1,30"
        if formatted.hasSuffix("0") {
            return String(formatted.dropLast())
        }
        return formatted
    }

    var body: some View {
        VStack(spacing: 14) {
            // Preset speed buttons
            HStack(spacing: 4) {
                ForEach(presets, id: \.self) { rate in
                    let isSelected = abs(satellite.playbackRate - rate) < 0.01

                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            satellite.setPlaybackRate(rate)
                        }
                    } label: {
                        Text(formatRate(rate))
                            .font(.system(.subheadline, design: .rounded, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                            .frame(minWidth: 36, minHeight: 30)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(.white.opacity(0.2))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Scrubber with bars
            GeometryReader { geo in
                let width = geo.size.width - 40 // account for icons
                let fraction = (satellite.playbackRate - minRate) / (maxRate - minRate)

                HStack(spacing: 0) {
                    // Turtle
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 20)

                    // Bars
                    HStack(alignment: .center, spacing: 2.5) {
                        ForEach(0..<barCount, id: \.self) { i in
                            let barFraction = Double(i) / Double(barCount - 1)
                            let isActive = barFraction <= fraction

                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(isActive ? .white : .white.opacity(0.2))
                                .frame(width: 2.5, height: barHeight(for: i))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let pct = max(0, min(1, value.location.x / width))
                                let rate = minRate + pct * (maxRate - minRate)
                                satellite.setPlaybackRate(snap(rate))
                            }
                    )
                    .overlay {
                        // Indicator needle
                        GeometryReader { barGeo in
                            Rectangle()
                                .fill(.white)
                                .frame(width: 2, height: 28)
                                .position(
                                    x: fraction * barGeo.size.width,
                                    y: barGeo.size.height / 2
                                )
                        }
                    }

                    // Rabbit
                    Image(systemName: "hare.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 20)
                }
            }
            .frame(height: 28)

            // Label
            Text("playback.rate.adjust")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.5), in: .rect(cornerRadius: 16))
        .background(.black.opacity(0.7), in: .rect(cornerRadius: 16))
        .frame(width: 300)
        .onTapGesture {} // prevent passthrough
    }

    private func barHeight(for index: Int) -> CGFloat {
        // Taller in the middle, shorter at edges
        let center = Double(barCount - 1) / 2.0
        let normalized = 1.0 - abs(Double(index) - center) / center
        return 6 + normalized * 16
    }

    private func snap(_ rate: Double) -> Double {
        for preset in presets {
            if abs(rate - preset) < 0.06 {
                return preset
            }
        }
        return (rate * 10).rounded() / 10
    }
}
struct PlaybackSleepTimerButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    private var sleepTimerIntervals: [Double] { AppSettings.shared.sleepTimerIntervals }

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
    private func menuContent() -> some View {
        if let sleepTimer = satellite.sleepTimer {
            switch sleepTimer {
                case .chapters(let amount, _):
                    ControlGroup {
                        Button("action.decrease", systemImage: "minus") {
                            if amount > 1 {
                                satellite.setSleepTimer(.chapters(amount - 1))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }

                        Text(amount, format: .number)

                        Button("action.increase", systemImage: "plus") {
                            satellite.setSleepTimer(.chapters(amount + 1))
                        }
                    }
                case .interval(let expiresAt, let extend):
                    let remainingSleepTime = Date.now.distance(to: expiresAt)

                    ControlGroup {
                        Button("action.decrease", systemImage: "minus") {
                            if remainingSleepTime > 60 {
                                satellite.setSleepTimer(.interval(expiresAt.advanced(by: -60), extend))
                            } else {
                                satellite.setSleepTimer(nil)
                            }
                        }

                        Button("action.increase", systemImage: "plus") {
                            satellite.setSleepTimer(.interval(expiresAt.advanced(by: 60), extend))
                        }
                    }
            }

            Divider()

            Button("playback.sleepTimer.extend", systemImage: "plus") {
                satellite.extendSleepTimer()
            }

            Button("playback.sleepTimer.cancel", systemImage: "alarm") {
                satellite.setSleepTimer(nil)
            }
        } else {
            if satellite.chapter != nil {
                Button("playback.sleepTimer.chapter", systemImage: "append.page") {
                    satellite.setSleepTimer(.chapters(1))
                }

                Divider()
            }

            ForEach(sleepTimerIntervals, id: \.hashValue) { interval in
                Button {
                    satellite.setSleepTimer(.interval(interval))
                } label: {
                    Text(interval, format: .duration(unitsStyle: .full, allowedUnits: [.minute, .hour]))
                }
            }
        }
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
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Menu {
                menuContent()
            } label: {
                label(at: context.date)
            }
            .menuActionDismissBehavior(.disabled)
            .hoverEffect(.highlight)
            .padding(-12)
            .accessibilityLabel("playback.sleepTimer")
            .accessibilityValue(Text(accessibilityValue(at: context.date)))
        }
    }
}
struct PlaybackAirPlayButton: View {
    @Environment(Satellite.self) private var satellite

    private var tintColor: TintColor { AppSettings.shared.tintColor }

    private let routePickerView = AVRoutePickerView()

    var body: some View {
        Button {
            for view in routePickerView.subviews {
                guard let button = view as? UIButton else {
                    continue
                }

                button.sendActions(for: .touchUpInside)
                break
            }
        } label: {
            Label("airPlay", systemImage: satellite.route?.icon ?? "airplay.audio")
                .padding(12)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(satellite.route?.isHighlighted == true ? tintColor.color : Color.primary)
                .contentTransition(.symbolEffect(.replace))
                .contentShape(.rect(cornerRadius: 4))
        }
        .hoverEffect(.highlight)
        .padding(-12)
    }
}

struct PlaybackActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel

    @ViewBuilder
    private var queueButton: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.isRatePickerVisible = false
                viewModel.isQueueVisible.toggle()
            }
        } label: {
            Label("playback.queue", systemImage: "list.number")
                .padding(12)
                .contentShape(.rect)
        }
        .background(.gray.opacity(viewModel.isQueueVisible ? 0.2 : 0), in: .circle)
        .padding(-12)
    }

    var body: some View {
        LazyVGrid(columns: .init(repeating: .init(alignment: .centerFirstTextBaseline), count: 4)) {
            PlaybackRateButton()
            PlaybackSleepTimerButton()
            PlaybackAirPlayButton()
            queueButton
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.headline)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .geometryGroup()
        .compositingGroup()
    }
}

private struct PlaybackSlider<MiddleContent: View>: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.colorScheme) private var colorScheme

    private var durationToggled: Bool {
        get { AppSettings.shared.durationToggled }
        nonmutating set { AppSettings.shared.durationToggled = newValue }
    }
    private var lockSeekBar: Bool { AppSettings.shared.lockSeekBar }

    let percentage: Percentage
    @Binding var seeking: Percentage?

    let currentTime: TimeInterval?
    let duration: TimeInterval?

    let textFirst: Bool

    @ViewBuilder let middleContent: () -> MiddleContent
    let complete: (_: Percentage) -> Void

    @State private var dragStartValue: Percentage?
    @State private var lastDragVelocity: CGFloat? = nil

    @ScaledMetric private var mutedHeight = 11
    @ScaledMetric private var activeHeight = 14

    private let height: CGFloat = 8
    private let hitTargetPadding: CGFloat = 12

    private var trailingTime: TimeInterval? {
        guard let currentTime, let duration else {
            return nil
        }

        let base: TimeInterval

        if durationToggled {
            base = (duration - currentTime)
        } else {
            base = duration
        }

        return base
    }

    @ViewBuilder
    private var text: some View {
        Group {
            if let currentTime, let trailingTime {
                LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .center), .init(alignment: .trailing)]) {
                    Text(currentTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))

                    middleContent()

                    Button {
                        AppSettings.shared.durationToggled.toggle()
                    } label: {
                        HStack(spacing: 0) {
                            if durationToggled {
                                Text(verbatim: "-")
                            }

                            Text(trailingTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                                .contentTransition(.numericText(value: trailingTime))
                                .animation(.smooth, value: durationToggled)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(verbatim: "PLACEHOLDER")
                    .hidden()
            }
        }
        .font(seeking == nil ? .caption2 : .footnote)
        .fontDesign(.rounded)
        .frame(height: activeHeight)
        .foregroundStyle(seeking == nil ? .secondary : .primary)
    }

    private var adjustedHeight: CGFloat {
        height * (seeking == nil ? 1 : 2)
    }

    var body: some View {
        VStack(spacing: 6) {
            if textFirst {
                text
            }

            GeometryReader { geometry in
                let width = geometry.size.width * min(1, max(0, CGFloat(seeking ?? percentage)))

                ZStack(alignment: .leading) {
                    if colorScheme == .dark {
                        Rectangle()
                            .fill(.background.tertiary)
                            .saturation(1.6)
                    } else {
                        Rectangle()
                            .fill(.background.secondary)
                            .saturation(1.6)
                    }

                    Rectangle()
                        .frame(width: width)
                        .foregroundStyle(.primary)
                        .animation(.smooth, value: width)
                }
                .frame(height: adjustedHeight, alignment: textFirst ? .bottom : .top)
                .clipShape(.rect(cornerRadius: .infinity))
                .padding(.vertical, hitTargetPadding)
                .contentShape(.rect)
                .highPriorityGesture(DragGesture(minimumDistance: 10.0)
                    .onChanged {
                        guard !lockSeekBar else {
                            return
                        }

                        if dragStartValue == nil {
                            dragStartValue = percentage
                        }

                        let width = geometry.size.width
                        let offset = min(width, max(-width, $0.translation.width))

                        let moved: Percentage = .init(offset / width)
                        let velocity = abs($0.velocity.width)
                        let acceleration: Percentage

                        lastDragVelocity = velocity

                        if velocity < 600 {
                            acceleration = 1
                        } else if velocity < 1000 {
                            acceleration = 2
                        } else {
                            acceleration = 3
                        }

                        let modifier = moved * acceleration
                        seeking = min(1, max(0, dragStartValue! + modifier))
                    }
                    .onEnded {
                        if let lastDragVelocity, lastDragVelocity > 1000, let seeking {
                            let modifier = $0.translation.width < 0 ? -1.1 : 1.1
                            self.seeking = min(1, seeking * modifier)
                        }

                        if let seeking {
                            complete(seeking)
                        }

                        dragStartValue = nil
                        lastDragVelocity = nil
                    })
            }
            .frame(height: hitTargetPadding * 2 + adjustedHeight)
            .padding(.vertical, -hitTargetPadding)

            if !textFirst {
                text
            }
        }
        .frame(height: height * 2 + activeHeight + 6)
        .compositingGroup()
        .animation(.smooth, value: seeking)
        .accessibilityRepresentation {
            if let currentTime, let duration {
                Slider(value: .init() {
                    duration * percentage
                } set: {
                    seeking = min(1, max(0, $0 / duration))
                }, in: 0...duration) {
                    Text(verbatim: "\(currentTime.formatted(.duration(unitsStyle: .spellOut, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))) / \(duration.formatted(.duration(unitsStyle: .spellOut, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))))")
                }
            } else {
                Slider(value: .init() {
                    percentage
                } set: {
                    seeking = $0
                }, in: 0...1) {
                    Text("volume")
                }
            }
        }
    }
}
private struct BottomSlider: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    private var replaceVolumeWithTotalProgress: Bool { AppSettings.shared.replaceVolumeWithTotalProgress }

    private var currentTime: TimeInterval {
        if let seekingTotal = viewModel.seekingTotal {
            satellite.duration * seekingTotal
        } else {
            satellite.currentTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seekingTotal != nil {
            satellite.duration - currentTime
        } else {
            satellite.duration
        }
    }

    private var remaining: TimeInterval {
        if viewModel.seekingTotal != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.duration - satellite.currentTime) * (1 / satellite.playbackRate)
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        if replaceVolumeWithTotalProgress, satellite.chapter != nil {
            PlaybackSlider(percentage: satellite.playedTotal, seeking: $viewModel.seekingTotal, currentTime: currentTime, duration: duration, textFirst: true) {
                Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                    .contentTransition(.numericText())
                    .transition(.opacity)
                    .animation(.smooth, value: remaining)
            } complete: {
                satellite.seek(to: satellite.duration * $0, insideChapter: false) {
                    Task { @MainActor in
                        viewModel.seekingTotal = nil
                    }
                }
            }
        } else {
            PlaybackSlider(percentage: satellite.volume, seeking: $viewModel.volumePreview, currentTime: nil, duration: nil, textFirst: true) {
                Spacer()
            } complete: { _ in
                viewModel.volumePreview = nil
            }
            .onChange(of: viewModel.volumePreview) {
                if let volume = viewModel.volumePreview {
                    Task {
                        await AudioPlayer.shared.setVolume(volume)
                    }
                }
            }
        }
    }
}

private struct StopPlaybackButton: View {
    @Environment(Satellite.self) private var satellite

    var body: some View {
        Button("playback.stop", systemImage: "stop.fill") {
            satellite.stop()
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var percentage: Percentage = 0.5
    @Previewable @State var seeking: Percentage? = nil

    VStack(spacing: 20) {
        PlaybackSlider(percentage: percentage, seeking: $seeking, currentTime: 10, duration: 20, textFirst: false) {
            Text("ABC")
        } complete: { _ in
            seeking = nil
        }

        PlaybackSlider(percentage: percentage, seeking: $seeking, currentTime: nil, duration: nil, textFirst: true) {
            Spacer()
        } complete: { _ in
            seeking = nil
        }
    }
    .previewEnvironment()
}

#Preview {
    PlaybackTitle(showTertiarySupplements: true)
        .previewEnvironment()
}
#Preview {
    PlaybackControls()
        .previewEnvironment()
}
#Preview {
    PlaybackActions()
        .previewEnvironment()
}
#endif
