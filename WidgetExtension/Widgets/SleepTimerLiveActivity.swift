//
//  SleepTimerLiveActivity.swift
//  WidgetExtension
//
//  Created by Rasmus Krämer on 28.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import OSLog
import ShelfPlayerKit

private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "SleepTimerLiveActivity")

private struct Actions: View {
    let state: SleepTimerLiveActivityAttributes.ContentState

    private var tintColor: Color { AppSettings.shared.tintColor.color }

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if let chapters = state.chapters {
                    Group {
                        if chapters > 1 {
                            Button(intent: SetSleepTimerIntent(amount: chapters - 1, type: .chapters)) {
                                ZStack {
                                    Image(systemName: "plus")
                                        .hidden()
                                    Label("decrease", systemImage: "minus")
                                }
                            }
                        } else {
                            Button("sleepTimer.cancel", systemImage: "xmark", intent: CancelSleepTimerIntent())
                                .tint(.white)
                        }

                        Button("increase", systemImage: "plus", intent: SetSleepTimerIntent(amount: chapters + 1, type: .chapters))
                    }
                    .tint(tintColor)
                } else {
                    Button("sleepTimer.extend", systemImage: "plus", intent: ExtendSleepTimerIntent())
                        .tint(tintColor)
                    Button("sleepTimer.cancel", systemImage: "xmark", intent: CancelSleepTimerIntent())
                        .tint(.white)
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }
}

struct SleepTimerLiveActivity: Widget {
    private func color(isStale: Bool) -> Color {
        if isStale {
            .gray
        } else {
            AppSettings.shared.tintColor.color
        }
    }

    @ViewBuilder
    private func time(state: SleepTimerLiveActivityAttributes.ContentState, isStale: Bool, fixedWidth: Bool) -> some View {
        Group {
            if let deadline = state.deadline {
                if !state.isPlaying {
                    Button("paused", systemImage: "pause.fill", intent: PlayIntent())
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                } else {
                    if fixedWidth {
                        Text(verbatim: "00:00:00")
                            .hidden()
                            .overlay(alignment: .trailing) {
                                Text(deadline, style: .timer)
                                    .multilineTextAlignment(.trailing)
                            }
                    } else {
                        Text(deadline, style: .timer)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } else if let chapters = state.chapters {
                Text("\(Text("chapters")) \(chapters)")
            }
        }
        .lineLimit(1)
        .fontDesign(.rounded)
        .foregroundStyle(color(isStale: isStale))
    }

    @ViewBuilder
    private func leadingLabel(isStale: Bool) -> some View {
        Label("sleepTimer", systemImage: "moon.zzz")
            .foregroundStyle(color(isStale: isStale))
    }

    @ViewBuilder
    private func progressView(attributes: SleepTimerLiveActivityAttributes, state: SleepTimerLiveActivityAttributes.ContentState, isStale: Bool) -> some View {
        if state.isPlaying {
            if let deadline = state.deadline {
                ProgressView(timerInterval: attributes.started...deadline, countsDown: true) {
                    Text("sleepTimer")
                } currentValueLabel: {
                    leadingLabel(isStale: isStale)
                }
                .progressViewStyle(.circular)
                .frame(width: 24)
                .tint(color(isStale: isStale))
            } else if state.chapters != nil {
                Label("chapters", systemImage: "alarm")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(color(isStale: isStale))
            }
        } else {
            leadingLabel(isStale: isStale)
                .labelStyle(.iconOnly)
        }
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerLiveActivityAttributes.self) { context in
            let _ = logger.info("SleepTimer live activity content render: deadline=\(String(describing: context.state.deadline), privacy: .public) chapters=\(String(describing: context.state.chapters), privacy: .public) isPlaying=\(context.state.isPlaying, privacy: .public) isStale=\(context.isStale, privacy: .public)")
            HStack(alignment: .bottom, spacing: 0) {
                Actions(state: context.state)
                    .font(.largeTitle)

                Spacer(minLength: 12)

                time(state: context.state, isStale: context.isStale, fixedWidth: false)
                    .font(.largeTitle)
            }
            .padding(12)
            .background()
            .colorScheme(.dark)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            logger.info("SleepTimer dynamic island render: deadline=\(String(describing: context.state.deadline), privacy: .public) chapters=\(String(describing: context.state.chapters), privacy: .public) isPlaying=\(context.state.isPlaying, privacy: .public) isStale=\(context.isStale, privacy: .public)")
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Actions(state: context.state)
                        .font(.title)
                        .frame(maxHeight: .infinity)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        time(state: context.state, isStale: context.isStale, fixedWidth: true)
                            .font(.largeTitle)
                    }
                }
            } compactLeading: {
                progressView(attributes: context.attributes, state: context.state, isStale: context.isStale)
            } compactTrailing: {
                time(state: context.state, isStale: context.isStale, fixedWidth: true)
            } minimal: {
                progressView(attributes: context.attributes, state: context.state, isStale: context.isStale)
            }
            .keylineTint(color(isStale: context.isStale))
        }
    }
}

#if DEBUG
#Preview(as: .content, using: SleepTimerLiveActivityAttributes(started: .now)) {
    SleepTimerLiveActivity()
} contentStates: {
    SleepTimerLiveActivityAttributes.ContentState(deadline: .now.advanced(by: 60), chapters: nil, isPlaying: true)
    SleepTimerLiveActivityAttributes.ContentState(deadline: .now.advanced(by: 60 * 5), chapters: nil, isPlaying: false)
}
#Preview(as: .content, using: SleepTimerLiveActivityAttributes(started: .now)) {
    SleepTimerLiveActivity()
} contentStates: {
    SleepTimerLiveActivityAttributes.ContentState(deadline: nil, chapters: 4, isPlaying: true)
    SleepTimerLiveActivityAttributes.ContentState(deadline: nil, chapters: 4, isPlaying: false)
}
#endif
