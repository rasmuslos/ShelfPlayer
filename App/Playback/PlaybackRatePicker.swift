//
//  PlaybackRatePicker.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

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
            HStack(alignment: .firstTextBaseline, spacing: 0) {
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
        .modify(if: viewModel.isRatePickerVisible) {
            $0.glassEffect(.clear.interactive(), in: .circle)
        }
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
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @Binding var isPresented: Bool
    let onMeshBackground: Bool

    @State private var dragAnchorRate: Double?
    @State private var isDragging = false
    @State private var notifyGroupingSave = false
    @State private var notifyGroupingError = false
    @State private var storedGroupingRate: Double?
    @State private var lastNearestPreset: Double?

    private let minRate: Double = 0.1
    private let maxRate: Double = 4.0
    private let step: Double = 0.1
    private let tickSpacing: CGFloat = 16

    private var presets: [Double] { AppSettings.shared.playbackRates }
    private var defaultRate: Double { AppSettings.shared.defaultPlaybackRate }

    private var primaryColor: Color {
        onMeshBackground ? .white : .primary
    }

    private var secondaryColor: Color {
        onMeshBackground ? .white.opacity(0.6) : .secondary
    }

    private var effectiveGroupingDefault: Double {
        storedGroupingRate ?? defaultRate
    }

    private var canSaveGroupingDefault: Bool {
        grouping != nil && abs(satellite.playbackRate - effectiveGroupingDefault) > 0.001
    }

    private enum GroupingKind {
        case podcast
        case series

        var label: LocalizedStringKey {
            switch self {
                case .podcast: "playback.rate.setPodcastDefault"
                case .series: "playback.rate.setSeriesDefault"
            }
        }
    }

    private var grouping: (id: ItemIdentifier, kind: GroupingKind)? {
        if let episode = satellite.nowPlayingItem as? Episode {
            return (episode.podcastID, .podcast)
        }
        if satellite.nowPlayingItem is Audiobook, let first = viewModel.seriesIDs.first {
            return (first.0, .series)
        }
        return nil
    }

    private func snappedRate(_ rate: Double) -> Double {
        let clamped = max(minRate, min(maxRate, rate))
        return (clamped / step).rounded() * step
    }

    var body: some View {
        VStack(spacing: 0) {
            groupingDefaultControl
                .padding(.bottom, 8)

            Spacer(minLength: 8)

            rateDisplay

            Spacer(minLength: 20)

            ruler
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
        .contentShape(.rect)
        .onTapGesture {} // prevent passthrough
        .hapticFeedback(.success, trigger: notifyGroupingSave)
        .hapticFeedback(.error, trigger: notifyGroupingError)
        .task(id: grouping?.id) {
            if let grouping {
                storedGroupingRate = await PersistenceManager.shared.item.playbackRate(for: grouping.id)
            } else {
                storedGroupingRate = nil
            }
        }
    }

    @ViewBuilder
    private var groupingDefaultControl: some View {
        ZStack {
            if canSaveGroupingDefault, let grouping {
                Button {
                    setAsGroupingDefault(itemID: grouping.id)
                } label: {
                    Label(grouping.kind.label, systemImage: "pin")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(primaryColor)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.clear.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.4, anchor: .top).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 34)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: canSaveGroupingDefault)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: grouping?.id)
    }

    @ViewBuilder
    private var rateDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Image(decorative: "xsign")
                .font(.system(size: 40, weight: .regular))
                .padding(.trailing, 4)
                .hidden()

            Text(satellite.playbackRate, format: .playbackRate.hideX().fractionDigits(1))
                .font(.system(size: 96, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: satellite.playbackRate))

            Image(decorative: "xsign")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
        .scaleEffect(isDragging ? 1.05 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: satellite.playbackRate)
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
                    .font(.system(size: 9))
                    .foregroundStyle(primaryColor)
                    .frame(width: width, height: 10)
                    .scaleEffect(isDragging ? 1.25 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isDragging)

                RulerCanvas(rate: satellite.playbackRate,
                            minRate: minRate,
                            maxRate: maxRate,
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
                            .init(color: .black, location: 0.1),
                            .init(color: .black, location: 0.9),
                            .init(color: .clear, location: 1)
                        ], startPoint: .leading, endPoint: .trailing)
                        .frame(width: width)
                    }
                    .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.75), value: satellite.playbackRate)
            }
            .frame(width: width, height: geo.size.height, alignment: .top)
            .contentShape(.rect)
            .hapticFeedback(.selection, trigger: satellite.playbackRate)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragAnchorRate == nil {
                            dragAnchorRate = satellite.playbackRate
                            isDragging = true
                        }

                        let delta = -value.translation.width / tickSpacing * step
                        let target = snappedRate(dragAnchorRate! + delta)

                        if abs(satellite.playbackRate - target) > 0.001 {
                            satellite.setPlaybackRate(target)
                        }
                    }
                    .onEnded { _ in
                        dragAnchorRate = nil
                        isDragging = false
                    }
            )
        }
    }

    @ViewBuilder
    private var presetButtons: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { rate in
                        let isSelected = abs(satellite.playbackRate - rate) < 0.001

                        Button {
                            satellite.setPlaybackRate(rate)
                        } label: {
                            Text(rate, format: .playbackRate.hideX().fractionDigits(1))
                                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? primaryColor : secondaryColor)
                                .lineLimit(1)
                                .fixedSize()
                                .frame(minWidth: 44)
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .glassEffect(isSelected ? .clear.interactive().tint(primaryColor.opacity(0.12)) : .clear.interactive(), in: .capsule)
                                .scaleEffect(isSelected ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
                        .id(rate)
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
            .onChange(of: satellite.playbackRate) { _, rate in
                let nearest = presets.min(by: { abs($0 - rate) < abs($1 - rate) })
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
        presets.min(by: { abs($0 - satellite.playbackRate) < abs($1 - satellite.playbackRate) })
    }

    private func setAsGroupingDefault(itemID: ItemIdentifier) {
        let rate = satellite.playbackRate

        Task {
            do {
                try await PersistenceManager.shared.item.setPlaybackRate(rate, for: itemID)
                storedGroupingRate = rate
                notifyGroupingSave.toggle()
            } catch {
                notifyGroupingError.toggle()
            }
        }
    }
}

private struct RulerCanvas: View, Animatable {
    var rate: Double
    let minRate: Double
    let maxRate: Double
    let step: Double
    let tickSpacing: CGFloat
    let tickHeight: CGFloat
    let labelSpacing: CGFloat
    let labelHeight: CGFloat
    let primaryColor: Color
    let secondaryColor: Color

    var animatableData: Double {
        get { rate }
        set { rate = newValue }
    }

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            let centerX = size.width / 2
            let tickCount = Int(((maxRate - minRate) / step).rounded()) + 1
            let currentIndex = (rate - minRate) / step
            let offsetX = centerX - CGFloat(currentIndex) * tickSpacing - tickSpacing / 2

            let baseMajorHeight: CGFloat = 20
            let baseMinorHeight: CGFloat = 12
            let labelY = tickHeight + labelSpacing + labelHeight / 2

            for index in 0..<tickCount {
                let tickX = offsetX + CGFloat(index) * tickSpacing + tickSpacing / 2
                if tickX < -8 || tickX > size.width + 8 { continue }

                let rateValue = minRate + Double(index) * step
                let major = (Int((rateValue * 10).rounded()) % 5) == 0
                let fracDistance = abs(Double(index) - currentIndex)

                let height: CGFloat
                let opacity: Double

                if fracDistance < 1 {
                    let t = fracDistance
                    height = tickHeight - (tickHeight - tickHeight * 0.55) * CGFloat(t)
                    opacity = 1.0 - 0.25 * t
                } else if fracDistance < 2 {
                    let t = fracDistance - 1
                    let start: CGFloat = tickHeight * 0.55
                    let end: CGFloat = major ? baseMajorHeight + 2 : baseMinorHeight + 4
                    height = start + (end - start) * CGFloat(t)
                    let endOpacity = major ? 0.85 : 0.35
                    opacity = 0.75 + (endOpacity - 0.75) * t
                } else {
                    height = major ? baseMajorHeight : baseMinorHeight
                    opacity = major ? 0.85 : 0.35
                }

                let barRect = CGRect(x: tickX - 0.75, y: tickHeight - height, width: 1.5, height: height)
                context.fill(Path(barRect), with: .color(primaryColor.opacity(opacity)))

                if major {
                    let text = Text(rateValue, format: .playbackRate.hideX().fractionDigits(1))
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
    PlaybackRateButton()
        .previewEnvironment()
}

#Preview {
    PlaybackRatePickerCard(isPresented: .constant(true), onMeshBackground: false)
        .previewEnvironment()
}
#endif
