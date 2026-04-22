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

    @State private var dragAnchorRate: Double?
    @State private var isDragging = false
    @State private var notifyGroupingSave = false
    @State private var notifyGroupingError = false

    private let minRate: Double = 0.1
    private let maxRate: Double = 4.0
    private let step: Double = 0.1
    private let tickSpacing: CGFloat = 16

    private var presets: [Double] { AppSettings.shared.playbackRates }
    private var defaultRate: Double { AppSettings.shared.defaultPlaybackRate }

    private var hasChanged: Bool {
        abs(satellite.playbackRate - defaultRate) > 0.001
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

    private func isMajorTick(_ rate: Double) -> Bool {
        let rounded = (rate * 10).rounded()
        return Int(rounded) % 5 == 0
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

            resetControl

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
    }

    @ViewBuilder
    private var groupingDefaultControl: some View {
        ZStack {
            if hasChanged, let grouping {
                Button {
                    setAsGroupingDefault(itemID: grouping.id)
                } label: {
                    Label(grouping.kind.label, systemImage: "pin")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.28), in: .capsule)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.4, anchor: .top).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 34)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: hasChanged)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: grouping?.id)
    }

    @ViewBuilder
    private var resetControl: some View {
        ZStack {
            if hasChanged {
                Button {
                    satellite.setPlaybackRate(defaultRate)
                } label: {
                    Label("action.reset", systemImage: "arrow.counterclockwise")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.28), in: .capsule)
                }
                .buttonStyle(.plain)
                .transition(.scale(scale: 0.4, anchor: .bottom).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 34)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: hasChanged)
    }

    @ViewBuilder
    private var rateDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(satellite.playbackRate, format: .playbackRate.hideX())
                .font(.system(size: 96, weight: .bold))
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
            let centerX = width / 2
            let tickCount = Int(((maxRate - minRate) / step).rounded()) + 1
            let currentIndex = CGFloat(satellite.playbackRate - minRate) / CGFloat(step)
            let activeIndex = Int(currentIndex.rounded())
            let offsetX = centerX - currentIndex * tickSpacing - tickSpacing / 2

            let maxBarHeight: CGFloat = 40
            let baseMajorHeight: CGFloat = 20
            let baseMinorHeight: CGFloat = 12

            VStack(spacing: 6) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.primary)
                    .frame(width: width, height: 10)
                    .scaleEffect(isDragging ? 1.25 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isDragging)

                HStack(spacing: 0) {
                    ForEach(0..<tickCount, id: \.self) { index in
                        let rate = minRate + Double(index) * step
                        let major = isMajorTick(rate)
                        let distance = abs(index - activeIndex)

                        let height: CGFloat = {
                            switch distance {
                                case 0: return maxBarHeight
                                case 1: return maxBarHeight * 0.55
                                case 2: return major ? baseMajorHeight + 2 : baseMinorHeight + 4
                                default: return major ? baseMajorHeight : baseMinorHeight
                            }
                        }()

                        let opacity: Double = {
                            switch distance {
                                case 0: return 1.0
                                case 1: return 0.75
                                default: return major ? 0.85 : 0.35
                            }
                        }()

                        VStack(spacing: 6) {
                            Rectangle()
                                .fill(.primary.opacity(opacity))
                                .frame(width: 1.5, height: height)
                                .frame(height: maxBarHeight, alignment: .bottom)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: activeIndex)

                            Group {
                                if major {
                                    Text(rate, format: .playbackRate.hideX())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize()
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(height: 14)
                        }
                        .frame(width: tickSpacing)
                    }
                }
                .frame(width: width, alignment: .leading)
                .geometryGroup()
                .offset(x: offsetX)
                .animation(isDragging ? nil : .spring(response: 0.4, dampingFraction: 0.75), value: satellite.playbackRate)
                .mask(alignment: .leading) {
                    LinearGradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.1),
                        .init(color: .black, location: 0.9),
                        .init(color: .clear, location: 1)
                    ], startPoint: .leading, endPoint: .trailing)
                    .frame(width: width)
                }
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
                            Text(rate, format: .playbackRate.hideX())
                                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                                .lineLimit(1)
                                .fixedSize()
                                .frame(minWidth: 44)
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .background(.gray.opacity(isSelected ? 0.32 : 0.18), in: .capsule)
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
                    scrollProxy.scrollTo(nearest, anchor: .center)
                }
            }
            .onChange(of: satellite.playbackRate) {
                if let nearest = nearestPreset {
                    withAnimation(.smooth) {
                        scrollProxy.scrollTo(nearest, anchor: .center)
                    }
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
                notifyGroupingSave.toggle()
            } catch {
                notifyGroupingError.toggle()
            }
        }
    }
}

#if DEBUG
#Preview {
    PlaybackRatePickerCard(isPresented: .constant(true))
        .previewEnvironment()
}
#endif
