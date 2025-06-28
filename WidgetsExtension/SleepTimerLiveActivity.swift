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

struct SleepTimerLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var deadline: Date
        var isPlaying: Bool
    }
    
    var itemID: ItemIdentifier
}

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
private struct Time: View {
    let state: SleepTimerLiveActivityAttributes.ContentState
    
    var body: some View {
        Text(state.deadline, style: .timer)
            .font(.largeTitle)
            .foregroundStyle(Defaults[.tintColor].color)
            .multilineTextAlignment(.trailing)
    }
}

struct SleepTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepTimerLiveActivityAttributes.self) { context in
            HStack(spacing: 0) {
                Actions()
                
                Spacer(minLength: 12)
                
                Time(state: context.state)
                    .frame(alignment: .trailing)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)
            .background()
            .colorScheme(.dark)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
            } compactLeading: {
                Circle()
            } compactTrailing: {
                Text(context.state.deadline, style: .timer)
                    .frame(width: 200)
                    .border(.red)
            } minimal: {
                Text("abc")
            }
            .keylineTint(Color.red)
        }
    }
}

#if DEBUG
#Preview(as: .content, using: SleepTimerLiveActivityAttributes(itemID: .fixture)) {
    SleepTimerLiveActivity()
} contentStates: {
    SleepTimerLiveActivityAttributes.ContentState(deadline: .now.advanced(by: 60 * 5), isPlaying: true)
    SleepTimerLiveActivityAttributes.ContentState(deadline: .now.advanced(by: 60 * 5), isPlaying: false)
}
#endif
