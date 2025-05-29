//
//  Widgets.swift
//  Widgets
//
//  Created by Rasmus Krämer on 29.05.25.
//

import WidgetKit
import SwiftUI
import Defaults
import ShelfPlayerKit

struct ListenedTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.rfk.shelfPlayer.listenedToday", provider: ListenedTodayWidgetProvider()) {
            ListenedTodayWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.listenedToday.title"))
        .description(Text("widget.listenedToday.description"))
        .supportedFamilies([.accessoryCircular])
    }
}

struct ListenedTodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ListenedTodayTimelineEntry {
        ListenedTodayTimelineEntry(totalToday: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (ListenedTodayTimelineEntry) -> Void) {
        completion(getCurrent())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ListenedTodayTimelineEntry>) -> Void) {
        let tomorrowMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        
        let timeline = Timeline(entries: [
            getCurrent(),
            ListenedTodayTimelineEntry(date: tomorrowMidnight, totalToday: 0),
        ], policy: .atEnd)
        
        completion(timeline)
    }
    
    private func getCurrent() -> ListenedTodayTimelineEntry {
        let empty = ListenedTodayTimelineEntry(totalToday: 0)
        
        guard let current = Defaults[.listenedTodayWidgetValue] else {
            return empty
        }
        
        guard Calendar.current.isDateInToday(empty.date) else {
            Defaults[.listenedTodayWidgetValue] = nil
            return empty
        }
        
        return .init(totalToday: current.total)
    }
}

struct ListenedTodayTimelineEntry: TimelineEntry {
    var date: Date = .now
    
    let totalToday: Int?
    var target = Defaults[.listenTimeTarget]
    
    var percentage: Percentage {
        guard let totalToday else {
            return 0
        }
        
        return Double(totalToday) / Double(target)
    }
}

private struct ListenedTodayWidgetContent: View {
    let entry: ListenedTodayTimelineEntry
    
    var body: some View {
        Gauge(value: entry.percentage, in: 0...1) {
            Text(entry.target, format: .number)
        } currentValueLabel: {
            if let totalToday = entry.totalToday {
                Text(totalToday, format: .number)
            } else {
                Text(verbatim: "--")
            }
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) {}
    }
}

#Preview(as: .accessoryCircular) {
    ListenedTodayWidget()
} timeline: {
    ListenedTodayTimelineEntry(totalToday: nil, target: 30)
    ListenedTodayTimelineEntry(totalToday: 0, target: 30)
    ListenedTodayTimelineEntry(totalToday: 15, target: 30)
    ListenedTodayTimelineEntry(totalToday: 30, target: 30)
}
