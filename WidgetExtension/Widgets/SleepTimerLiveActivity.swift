//
//  WidgetExtensionAttributes.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import ShelfPlayerKit

private struct Actions: View {
    let state: SleepTimerLiveActivityAttributes.ContentState
    
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
                    .tint(Defaults[.tintColor].color)
                } else {
                    Button("sleepTimer.extend", systemImage: "plus", intent: ExtendSleepTimerIntent())
                        .tint(Defaults[.tintColor].color)
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
            Defaults[.tintColor].color
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
                Text("chapters")
                    .font(.body)
                + Text(verbatim: " ")
                + Text(chapters, format: .number)
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
            DynamicIsland {
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
