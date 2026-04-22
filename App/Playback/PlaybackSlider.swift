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
