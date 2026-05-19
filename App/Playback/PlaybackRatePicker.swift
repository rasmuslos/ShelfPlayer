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

    var onMeshBackground: Bool = false

    private var isOpen: Bool {
        viewModel.activeCard == .ratePicker
    }

    var body: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.activeCard = isOpen ? nil : .ratePicker
            }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
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
        .modify(if: isOpen) {
            $0.glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
        }
        .padding(-12)
        .accessibilityLabel("preferences.playbackRate")
        .accessibilityValue(Text(satellite.playbackRate.formatted(.playbackRate)))
        .accessibilityHint(Text(isOpen ? "playback.rate.hint.close" : "playback.rate.hint.open"))
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }
}

struct PlaybackRatePickerCard: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let onMeshBackground: Bool

    @State private var liveRate: Double = 1.0
    @State private var isCardDragging = false
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

    private func presetGlass(isSelected: Bool) -> Glass {
        let base: Glass = onMeshBackground ? .clear.interactive() : .regular.interactive()
        return isSelected ? base.tint(primaryColor.opacity(0.12)) : base
    }

    var body: some View {
        VStack(spacing: 0) {
            groupingDefaultControl
                .padding(.bottom, 8)

            Spacer(minLength: 8)

            rateDisplay

            Spacer(minLength: 20)

            RulerSlider(
                value: $liveRate,
                range: minRate...maxRate,
                step: step,
                tickSpacing: tickSpacing,
                majorStep: 0.5,
                labelStep: 0.5,
                labelText: { Text($0, format: .playbackRate.hideX().fractionDigits(1)) },
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                accessibilityLabel: "preferences.playbackRate",
                accessibilityValue: { Text($0.formatted(.playbackRate)) },
                onDragStart: {
                    viewModel.isCardSliderInUse = true
                    isCardDragging = true
                },
                onCommit: { final in
                    isCardDragging = false
                    viewModel.isCardSliderInUse = false
                    satellite.setPlaybackRate(final)
                }
            )
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
        .hapticFeedback(.success, trigger: notifyGroupingSave)
        .hapticFeedback(.error, trigger: notifyGroupingError)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("preferences.playbackRate")
        .accessibilityAction(.escape) {
            withAnimation(.snappy) {
                viewModel.activeCard = nil
            }
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
        .task(id: grouping?.id) {
            if let grouping {
                storedGroupingRate = await PersistenceManager.shared.item.playbackRate(for: grouping.id)
            } else {
                storedGroupingRate = nil
            }
        }
        .onAppear {
            liveRate = satellite.playbackRate
        }
        .onChange(of: satellite.playbackRate) { _, newRate in
            guard !isCardDragging else { return }
            liveRate = newRate
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
                        .glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
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

            Text(liveRate, format: .playbackRate.hideX().fractionDigits(1))
                .font(.system(size: 96, weight: .bold))
                .monospacedDigit()
                .modify(if: !isCardDragging) {
                    $0.contentTransition(.numericText(value: liveRate))
                }

            Image(decorative: "xsign")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
        .scaleEffect(isCardDragging ? 1.05 : 1)
        .animation(isCardDragging ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: liveRate)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCardDragging)
    }

    @ViewBuilder
    private var presetButtons: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { rate in
                        let isSelected = abs(liveRate - rate) < 0.001

                        Button {
                            liveRate = rate
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
                                .glassEffect(presetGlass(isSelected: isSelected), in: .capsule)
                                .scaleEffect(isSelected ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(isCardDragging ? nil : .spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
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
            .onChange(of: liveRate) { _, _ in
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
        presets.min(by: { abs($0 - liveRate) < abs($1 - liveRate) })
    }

    private func scrollToNearest(using scrollProxy: ScrollViewProxy) {
        guard let nearest = nearestPreset, nearest != lastNearestPreset else { return }
        lastNearestPreset = nearest
        withAnimation(.smooth) {
            scrollProxy.scrollTo(nearest, anchor: .center)
        }
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

#if DEBUG
#Preview("Rate button") {
    PlaybackRateButton()
        .previewEnvironment()
}

#Preview("Rate button on mesh") {
    ZStack {
        LinearGradient(colors: [.purple, .indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        PlaybackRateButton(onMeshBackground: true)
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
    .previewEnvironment()
}

#Preview("Rate picker card") {
    PlaybackRatePickerCard(onMeshBackground: false)
        .previewEnvironment()
}

#Preview("Rate picker on mesh") {
    ZStack {
        LinearGradient(colors: [.purple, .indigo, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        PlaybackRatePickerCard(onMeshBackground: true)
            .foregroundStyle(.white)
    }
    .preferredColorScheme(.dark)
    .previewEnvironment()
}
#endif
