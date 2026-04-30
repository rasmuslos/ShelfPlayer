//
//  ListenedTodayWidget.swift
//  WidgetExtension
//
//  Created by Rasmus Krämer on 29.05.25.
//

import WidgetKit
import SwiftUI
import OSLog
import ShelfPlayerKit

private let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ListenedTodayWidget")

private var tomorrowMidnight: Date {
    Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
}

struct ListenedTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.rfk.shelfPlayer.listenedToday", provider: ListenedTodayWidgetProvider()) {
            ListenedTodayWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.listenedToday"))
        .description(Text("widget.listenedToday.description"))
        .supportedFamilies([.accessoryCircular])
    }
}

struct ListenedTodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ListenedTodayTimelineEntry {
        ListenedTodayTimelineEntry(totalToday: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ListenedTodayTimelineEntry) -> Void) {
        logger.info("Generating ListenedToday snapshot")
        Task {
            completion(await getCurrent())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ListenedTodayTimelineEntry>) -> Void) {
        logger.info("Generating ListenedToday timeline")
        Task {
            let timeline = Timeline(entries: [
                await getCurrent(),
                ListenedTodayTimelineEntry(date: tomorrowMidnight, totalToday: 0),
            ], policy: .atEnd)

            completion(timeline)
        }
    }

    private func getCurrent() async -> ListenedTodayTimelineEntry {
        let empty = ListenedTodayTimelineEntry(totalToday: 0)

        guard let current = AppSettings.shared.listenedTodayWidgetValue else {
            logger.warning("No listenedTodayWidgetValue set; falling back to empty entry")
            return empty
        }

        guard tomorrowMidnight.distance(to: current.updated) < 0 else {
            logger.warning("listenedTodayWidgetValue stale (updated=\(current.updated, privacy: .public)); resetting")
            AppSettings.shared.listenedTodayWidgetValue = nil
            return empty
        }

        return .init(totalToday: current.total)
    }
}

struct ListenedTodayTimelineEntry: TimelineEntry {
    var date: Date = .now

    let totalToday: Int?
    var target: Int = AppSettings.shared.listenTimeTarget

    var percentage: Percentage {
        guard let totalToday else {
            return 0
        }

        return min(1, max(0, Double(totalToday) / Double(target)))
    }
}

private struct ListenedTodayWidgetContent: View {
    let entry: ListenedTodayTimelineEntry

    var body: some View {
        Gauge(value: entry.percentage, in: 0...1) {
            Text(entry.target, format: .number)
                .contentTransition(.numericText(value: Double(entry.target)))
        } currentValueLabel: {
            if let totalToday = entry.totalToday {
                Text(totalToday, format: .number)
                    .contentTransition(.numericText(value: Double(totalToday)))
            } else {
                Text(verbatim: "--")
            }
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) {}
        .animation(.smooth, value: entry.target)
        .animation(.smooth, value: entry.totalToday)
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
