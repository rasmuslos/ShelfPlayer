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
    var body: some View {
        HStack(spacing: 8) {
            Group {
                Button("sleepTimer.extend", systemImage: "plus", intent: ExtendSleepTimerIntent())
                    .tint(Defaults[.tintColor].color)
                Button("sleepTimer.cancel", systemImage: "xmark", intent: CancelSleepTimerIntent())
                    .tint(.gray.opacity(0.8))
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderedProminent)
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
    private func time(state: SleepTimerLiveActivityAttributes.ContentState, isStale: Bool) -> some View {
        Group {
            if !state.isPlaying {
                Label("paused", systemImage: "pause.fill")
                    .labelStyle(.iconOnly)
            } else if let deadline = state.deadline {
                Text(verbatim: "00:00:00")
                    .hidden()
                    .overlay(alignment: .trailing) {
                        Text(deadline, style: .timer)
                            .multilineTextAlignment(.trailing)
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
                Label("chapters", systemImage: "append.page")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(color(isStale: isStale))
            }
        } else {
            leadingLabel(isStale: isStale)
                .labelStyle(.iconOnly)
        }
    }
    
    @ViewBuilder
    private func expanded(state: SleepTimerLiveActivityAttributes.ContentState, isStale: Bool) -> some View {
        HStack(spacing: 0) {
            Actions()
            
            Spacer(minLength: 12)
            
            time(state: state, isStale: isStale)
                .font(.largeTitle)
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerLiveActivityAttributes.self) { context in
            expanded(state: context.state, isStale: context.isStale)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 12)
                .background()
                .colorScheme(.dark)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    expanded(state: context.state, isStale: context.isStale)
                }
            } compactLeading: {
                progressView(attributes: context.attributes, state: context.state, isStale: context.isStale)
            } compactTrailing: {
                time(state: context.state, isStale: context.isStale)
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
    SleepTimerLiveActivityAttributes.ContentState(deadline: nil, chapters: 4, isPlaying: true)
    SleepTimerLiveActivityAttributes.ContentState(deadline: .now.advanced(by: 60 * 5), chapters: nil, isPlaying: false)
    SleepTimerLiveActivityAttributes.ContentState(deadline: nil, chapters: 3, isPlaying: false)
}
#endif
