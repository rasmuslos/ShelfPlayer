//
//  StatisticsSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import SwiftUI
import Charts
import ShelfPlayback

struct StatisticsView: View {
    @Environment(ConnectionStore.self) private var connectionStore

    @State private var viewModel: StatisticsViewModel

    init(connectionID: ItemIdentifier.ConnectionID) {
        _viewModel = .init(initialValue: .init(connectionID: connectionID))
    }

    private var currentConnection: FriendlyConnection? {
        connectionStore.connections.first { $0.id == viewModel.connectionID }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        return Group {
            if viewModel.isLoading && viewModel.stats == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.stats != nil {
                List {
                    Section {
                        TotalTimeCard(totalTime: viewModel.stats!.totalTime)
                    }

                    Section {
                        YearHeatmap(days: viewModel.allDays)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("statistics.yearActivity")
                    } footer: {
                        Text("statistics.yearActivity.count \(viewModel.activeDayCount)")
                    }

                    Section("statistics.dailyActivity") {
                        DailyActivityChart(days: viewModel.recentDays)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Section("statistics.byWeekday") {
                        WeekdayChart(dayOfWeek: viewModel.weekdayData)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    if !viewModel.topItems.isEmpty {
                        Section("statistics.topItems") {
                            TopItemsChart(items: viewModel.topItems)
                                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView("error.unavailable", systemImage: "chart.bar.xaxis", description: Text("error.unavailable.text"))
            }
        }
        .navigationTitle("statistics")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDetents([.large])
        .toolbar {
            if connectionStore.connections.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(selection: $viewModel.connectionID) {
                            ForEach(connectionStore.connections) { connection in
                                Text(connection.name).tag(connection.id)
                            }
                        } label: {
                            Text("statistics.account")
                        }
                    } label: {
                        Label(currentConnection?.name ?? String(localized: "statistics.account"), systemImage: "person.crop.circle")
                    }
                }
            }
        }
        .task(id: viewModel.connectionID) {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

// MARK: - Total Time Card

private struct TotalTimeCard: View {
    let totalTime: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(TimeInterval(totalTime), format: .duration(unitsStyle: .full, allowedUnits: [.day, .hour, .minute], maximumUnitCount: 2))
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("statistics.totalListeningTime")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Year Heatmap

private struct YearHeatmap: View {
    let days: [Date: Double]

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 13
    private let cellSpacing: CGFloat = 3

    private var maxTime: Double {
        days.values.max() ?? 1
    }

    private var activeDayCount: Int {
        days.values.filter { $0 > 0 }.count
    }

    private var weeks: [[Date?]] {
        let today = calendar.startOfDay(for: .now)
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: today) else { return [] }

        // Find the Monday on or before startDate
        var current = startDate
        while calendar.component(.weekday, from: current) != calendar.firstWeekday {
            current = calendar.date(byAdding: .day, value: -1, to: current)!
        }

        var weeks = [[Date?]]()
        while current <= today {
            var week = [Date?]()
            for _ in 0..<7 {
                if current >= startDate && current <= today {
                    week.append(current)
                } else {
                    week.append(nil)
                }
                current = calendar.date(byAdding: .day, value: 1, to: current)!
            }
            weeks.append(week)
        }
        return weeks
    }

    private func intensity(for date: Date) -> Double {
        guard maxTime > 0, let time = days[calendar.startOfDay(for: date)] else { return 0 }
        return min(time / maxTime, 1.0)
    }

    private func color(for intensity: Double) -> Color {
        if intensity <= 0 {
            return .primary.opacity(0.08)
        } else if intensity < 0.25 {
            return .accentColor.opacity(0.3)
        } else if intensity < 0.5 {
            return .accentColor.opacity(0.5)
        } else if intensity < 0.75 {
            return .accentColor.opacity(0.75)
        } else {
            return .accentColor
        }
    }

    private func monthLabels() -> [(String, Int)] {
        var labels = [(String, Int)]()
        var lastMonth = -1

        for (weekIndex, week) in weeks.enumerated() {
            for date in week.compactMap({ $0 }) {
                let month = calendar.component(.month, from: date)
                if month != lastMonth {
                    let symbol = calendar.shortMonthSymbols[month - 1]
                    labels.append((symbol, weekIndex))
                    lastMonth = month
                    break
                }
            }
        }

        if labels.count >= 2, labels[1].1 - labels[0].1 < 2 {
            labels.removeFirst()
        }
        if labels.count >= 2, weeks.count - labels[labels.count - 1].1 < 2 {
            labels.removeLast()
        }

        return labels
    }

    private var weekdayLabels: [(String, Int)] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekday = calendar.firstWeekday

        var result = [(String, Int)]()
        for row in 0..<7 {
            let weekdayIndex = (firstWeekday - 1 + row) % 7
            if row % 2 == 0 {
                result.append((symbols[weekdayIndex], row))
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Month labels
                    HStack(spacing: 0) {
                        Color.clear.frame(width: 28)

                        let labels = monthLabels()
                        let leadingOffset = labels.first?.1 ?? 0
                        if leadingOffset > 0 {
                            Color.clear
                                .frame(width: CGFloat(leadingOffset) * (cellSize + cellSpacing))
                        }

                        ForEach(Array(labels.enumerated()), id: \.offset) { index, item in
                            let (label, weekIndex) = item
                            let nextWeekIndex = index + 1 < labels.count ? labels[index + 1].1 : weeks.count
                            let columnWidth = CGFloat(nextWeekIndex - weekIndex) * (cellSize + cellSpacing)

                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: columnWidth, alignment: .leading)
                        }
                    }
                    .padding(.bottom, 4)

                    HStack(alignment: .top, spacing: 0) {
                        // Weekday labels
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                let weekdayIndex = (calendar.firstWeekday - 1 + row) % 7

                                if row % 2 == 0 {
                                    Text(calendar.shortStandaloneWeekdaySymbols[weekdayIndex])
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: cellSize, alignment: .trailing)
                                } else {
                                    Color.clear
                                        .frame(width: 28, height: cellSize)
                                }
                            }
                        }

                        // Grid
                        HStack(spacing: cellSpacing) {
                            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { dayIndex in
                                        if let date = week[dayIndex] {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(color(for: intensity(for: date)))
                                                .frame(width: cellSize, height: cellSize)
                                        } else {
                                            Color.clear
                                                .frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Legend
                    HStack(spacing: 4) {
                        Spacer()

                        Text("statistics.less")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach([0.0, 0.15, 0.35, 0.6, 1.0], id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: level))
                                .frame(width: cellSize, height: cellSize)
                        }

                        Text("statistics.more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .id("heatmapEnd")
            }
            .onAppear {
                proxy.scrollTo("heatmapEnd", anchor: .trailing)
            }
            }
        }
    }
}

// MARK: - Daily Activity Chart

private struct DailyActivityChart: View {
    let days: [(date: Date, time: Double)]

    var body: some View {
        Chart(days, id: \.date) { entry in
            BarMark(
                x: .value("statistics.date", entry.date, unit: .day),
                y: .value("statistics.hours", entry.time / 3600)
            )
            .foregroundStyle(.tint)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(verbatim: "\(Int(hours))h")
                    }
                }
            }
        }
        .padding(.top, 4)
        .frame(height: 200)
    }
}

// MARK: - Weekday Chart

private struct WeekdayChart: View {
    let dayOfWeek: [(day: String, time: Double)]

    var body: some View {
        Chart(dayOfWeek, id: \.day) { entry in
            BarMark(
                x: .value("statistics.day", entry.day),
                y: .value("statistics.hours", entry.time / 3600)
            )
            .foregroundStyle(.tint)
            .cornerRadius(3)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(verbatim: "\(Int(hours))h")
                    }
                }
            }
        }
        .padding(.top, 4)
        .frame(height: 180)
    }
}

// MARK: - Top Items Chart

private struct TopItemsChart: View {
    let items: [(title: String, time: Double)]

    var body: some View {
        Chart(items, id: \.title) { entry in
            BarMark(
                x: .value("statistics.hours", entry.time / 3600),
                y: .value("statistics.title", entry.title)
            )
            .foregroundStyle(.tint)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text(verbatim: "\(Int(hours))h")
                    }
                }
            }
        }
        .padding(.top, 4)
        .frame(height: CGFloat(items.count) * 36)
    }
}

// MARK: - ViewModel

@Observable @MainActor
final class StatisticsViewModel {
    var connectionID: ItemIdentifier.ConnectionID

    private(set) var stats: ListeningStatsPayload?
    private(set) var isLoading = false

    init(connectionID: ItemIdentifier.ConnectionID) {
        self.connectionID = connectionID
    }

    var activeDayCount: Int {
        allDays.values.filter { $0 > 0 }.count
    }

    var topItems: [(title: String, time: Double)] {
        guard let stats else { return [] }

        return stats.items.values
            .sorted { $0.timeListening > $1.timeListening }
            .prefix(10)
            .compactMap { item in
                guard let title = item.mediaMetadata.title else { return nil }
                return (title, item.timeListening)
            }
    }

    var allDays: [Date: Double] {
        guard let stats else { return [:] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var result = [Date: Double]()
        for (key, value) in stats.days {
            if let date = formatter.date(from: key) {
                let startOfDay = Calendar.current.startOfDay(for: date)
                result[startOfDay, default: 0] += value
            }
        }
        return result
    }

    var recentDays: [(date: Date, time: Double)] {
        guard let stats else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast

        return stats.days.compactMap { (key, value) in
            guard let date = formatter.date(from: key), date >= cutoff else { return nil }
            return (date, value)
        }
        .sorted { $0.0 < $1.0 }
    }

    var weekdayData: [(day: String, time: Double)] {
        guard let stats else { return [] }

        let orderedDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let englishToIndex: [String: Int] = [
            "Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4,
            "Friday": 5, "Saturday": 6, "Sunday": 0
        ]

        return orderedDays.compactMap { englishDay in
            let total = stats.dayOfWeek
                .filter { $0.key.lowercased() == englishDay.lowercased() }
                .values.reduce(0, +)

            let localizedTotal: Double
            if let idx = englishToIndex[englishDay] {
                let localizedName = calendar.weekdaySymbols[idx == 0 ? 0 : idx]
                localizedTotal = stats.dayOfWeek
                    .filter { $0.key.lowercased() == localizedName.lowercased() }
                    .values.reduce(0, +)
            } else {
                localizedTotal = 0
            }

            guard let idx = englishToIndex[englishDay] else { return nil }
            let symbol = weekdaySymbols[idx == 0 ? 0 : idx]
            return (symbol, total + localizedTotal)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            stats = try await ABSClient[connectionID].listeningStats()
        } catch {
            stats = nil
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        StatisticsView(connectionID: "preview")
    }
    .previewEnvironment()
}
#endif
