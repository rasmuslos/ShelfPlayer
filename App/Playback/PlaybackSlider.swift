//
//  PlaybackSlider.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackSlider<MiddleContent: View>: View {
    @Environment(Satellite.self) private var satellite

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

    @ScaledMetric private var mutedHeight = 11
    @ScaledMetric private var activeHeight = 14

    private let height: CGFloat = 8
    private let hitTargetPadding: CGFloat = 12

    private var isSeeking: Bool { seeking != nil }

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
                HStack(spacing: 0) {
                    Text(currentTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                        .accessibilityHidden(true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    middleContent()
                        .frame(maxWidth: .infinity, alignment: .center)

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
                    .frame(maxWidth: .infinity, alignment: .trailing)
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
                let currentSeeking = seeking
                let isSeeking = currentSeeking != nil
                let displayValue: Percentage = min(1, max(0, currentSeeking ?? percentage))
                let width = geometry.size.width * CGFloat(displayValue)
                let lensWidth: CGFloat = height * 2 * 1.6
                let lensHeight: CGFloat = height * 2 + 8

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.primary.opacity(0.18))

                    Rectangle()
                        .fill(.primary)
                        .frame(width: width)
                }
                .frame(height: adjustedHeight, alignment: textFirst ? .bottom : .top)
                .clipShape(.capsule)
                .animation(.spring(duration: 0.28, bounce: 0.22), value: adjustedHeight)
                .transaction(value: width) { $0.animation = nil }
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.clear)
                        .frame(width: lensWidth, height: lensHeight)
                        .glassEffect(.regular.tint(.primary.opacity(0.32)), in: .capsule)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
                        .scaleEffect(isSeeking ? 1 : 0.5, anchor: .center)
                        .opacity(isSeeking ? 1 : 0)
                        .animation(.spring(duration: 0.28, bounce: 0.22), value: isSeeking)
                        .offset(x: width - lensWidth / 2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(!isSeeking)
                }
                .padding(.vertical, hitTargetPadding)
                .contentShape(.rect)
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

                        seeking = min(1, max(0, dragStartValue! + moved))
                    }
                    .onEnded { _ in
                        if let seeking {
                            complete(seeking)
                        }

                        dragStartValue = nil
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
#endif
