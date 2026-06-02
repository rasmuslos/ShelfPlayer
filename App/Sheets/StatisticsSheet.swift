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

    @State private var listenedTodayTracker = ListenedTodayTracker.shared
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

                    Section {
                        ReadingGoalCalendar(days: viewModel.combinedDays(todaySeconds: TimeInterval(listenedTodayTracker.totalMinutesListenedToday) * 60), targetSeconds: TimeInterval(listenedTodayTracker.listenTimeTarget) * 60)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("statistics.readingGoalCalendar")
                    } footer: {
                        Text("statistics.readingGoalCalendar.footer \(listenedTodayTracker.listenTimeTarget)")
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

// MARK: - Reading Goal Calendar

private struct ReadingGoalCalendar: View {
    let days: [Date: Double]
    let targetSeconds: TimeInterval

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: .now)
    /// Sign of the most recent month transition. +1 = forward, -1 = backward.
    /// Picks the edge `.transition(.move(edge:))` slides toward.
    @State private var stepDirection: Int = 1

    private var calendar: Calendar { .current }

    private var monthRange: Range<Int>? {
        calendar.range(of: .day, in: .month, for: monthAnchor)
    }

    private var monthStart: Date? {
        let comps = calendar.dateComponents([.year, .month], from: monthAnchor)
        return calendar.date(from: comps)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: monthAnchor)
    }

    private var canStepForward: Bool {
        guard let monthStart,
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return false }
        return nextMonth <= calendar.startOfDay(for: .now)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstWeekday = calendar.firstWeekday
        return (0..<7).map { symbols[(firstWeekday - 1 + $0) % 7] }
    }

    private var leadingBlanks: Int {
        guard let monthStart else { return 0 }
        let weekday = calendar.component(.weekday, from: monthStart)
        return ((weekday - calendar.firstWeekday) + 7) % 7
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    step(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }
                .buttonStyle(.borderless)

                Text(monthLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
                    .animation(.smooth, value: monthLabel)

                Button {
                    step(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(canStepForward ? .primary : .tertiary)
                }
                .buttonStyle(.borderless)
                .disabled(!canStepForward)
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ZStack(alignment: .top) {
                MonthGrid(
                    monthAnchor: monthAnchor,
                    days: days,
                    targetSeconds: targetSeconds,
                    calendar: calendar
                )
                .id(monthAnchor)
                .transition(.asymmetric(
                    insertion: .move(edge: stepDirection >= 0 ? .trailing : .leading),
                    removal: .move(edge: stepDirection >= 0 ? .leading : .trailing)
                ))
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: monthAnchor)
            .clipped()
        }
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        step(by: 1)
                    } else if value.translation.width > threshold {
                        step(by: -1)
                    }
                }
        )
        .padding(.vertical, 8)
    }

    private struct MonthGrid: View {
        let monthAnchor: Date
        let days: [Date: Double]
        let targetSeconds: TimeInterval
        let calendar: Calendar

        private var monthRange: Range<Int>? {
            calendar.range(of: .day, in: .month, for: monthAnchor)
        }

        private var monthStart: Date? {
            let comps = calendar.dateComponents([.year, .month], from: monthAnchor)
            return calendar.date(from: comps)
        }

        private var leadingBlanks: Int {
            guard let monthStart else { return 0 }
            let weekday = calendar.component(.weekday, from: monthStart)
            return ((weekday - calendar.firstWeekday) + 7) % 7
        }

        var body: some View {
            if let monthStart, let monthRange {
                // Always render 6 rows so the grid height is stable across
                // months — otherwise the ZStack resizes mid-transition and the
                // slide animation looks broken.
                let rows = 6

                VStack(spacing: 6) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { col in
                                let cellIndex = row * 7 + col
                                let dayOffset = cellIndex - leadingBlanks
                                if dayOffset >= 0 && dayOffset < monthRange.count,
                                   let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) {
                                    DayCell(
                                        date: date,
                                        seconds: days[calendar.startOfDay(for: date)] ?? 0,
                                        targetSeconds: targetSeconds
                                    )
                                } else {
                                    Color.clear.aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func step(by months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: monthAnchor) else { return }
        if months > 0 {
            let today = calendar.startOfDay(for: .now)
            let comps = calendar.dateComponents([.year, .month], from: next)
            if let nextStart = calendar.date(from: comps), nextStart > today { return }
        }
        // Commit the direction first, then swap the month on the next runloop
        // tick. Changing both in one transaction leaves the *outgoing* grid
        // holding the previous direction's removal edge — its `.transition` was
        // baked in by the prior body — so the first reversal slides it the wrong
        // way. Rebuilding it with the new direction before the identity swap
        // keeps insertion and removal edges consistent.
        stepDirection = months
        Task { @MainActor in
            monthAnchor = next
        }
    }

    private struct DayCell: View {
        let date: Date
        let seconds: TimeInterval
        let targetSeconds: TimeInterval

        private var calendar: Calendar { .current }

        private var hit: Bool { targetSeconds > 0 && seconds >= targetSeconds }
        private var partial: Bool { !hit && seconds > 0 }
        private var isToday: Bool { calendar.isDateInToday(date) }
        private var isFuture: Bool { date > calendar.startOfDay(for: .now) }

        private var fill: Color {
            if hit { .accentColor }
            else if partial { .accentColor.opacity(0.25) }
            else { .clear }
        }

        private var stroke: Color {
            if isToday { .accentColor }
            else if !hit && !partial && !isFuture { .secondary.opacity(0.18) }
            else { .clear }
        }

        private var foreground: Color {
            if hit { .white }
            else if isFuture { .secondary.opacity(0.5) }
            else { .primary }
        }

        var body: some View {
            ZStack {
                Circle().fill(fill)
                Circle().strokeBorder(stroke, lineWidth: 1.5)

                Text(verbatim: "\(calendar.component(.day, from: date))")
                    .font(.caption.bold())
                    .foregroundStyle(foreground)
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
            .accessibilityValue(
                hit
                ? Text("statistics.readingGoalCalendar.dayHit")
                : Text(seconds > 0 ? "statistics.readingGoalCalendar.dayPartial" : "statistics.readingGoalCalendar.dayMiss")
            )
        }
    }
}

// MARK: - ViewModel

@Observable @MainActor
final class StatisticsViewModel {
    var connectionID: ItemIdentifier.ConnectionID

    private(set) var stats: ListeningStatsPayload?
    private(set) var isLoading = false

    private(set) var lockedDays: [Date: Double] = [:]

    init(connectionID: ItemIdentifier.ConnectionID) {
        self.connectionID = connectionID
    }

    /// Historical days from the locked subsystem (stable across midnight),
    /// overlaid with today's live `todaySeconds` so the calendar's "today" cell
    /// reflects in-flight listening.
    func combinedDays(todaySeconds: TimeInterval) -> [Date: Double] {
        var result = lockedDays
        if !lockedDays.isEmpty || todaySeconds > 0 {
            result[Calendar.current.startOfDay(for: .now)] = todaySeconds
        }
        return result
    }

    var activeDayCount: Int {
        // Match the heatmap's rolling 12-month window so the count never
        // exceeds a year. `stats.days` spans the user's entire history, so
        // counting it unfiltered yields impossible totals (e.g. 554).
        let today = Calendar.current.startOfDay(for: .now)
        guard let windowStart = Calendar.current.date(byAdding: .year, value: -1, to: today) else {
            return allDays.values.filter { $0 > 0 }.count
        }
        return allDays.filter { $0.key >= windowStart && $0.value > 0 }.count
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
            // Capture completed days first so the calendar uses stable values
            // even when post-midnight listening has inflated yesterday's API
            // total. captureCompletedDays only locks days the subsystem hasn't
            // already seen, so this is idempotent.
            try? await PersistenceManager.shared.listeningGoal.capture(stats: stats!, connectionID: connectionID)
        } catch {
            stats = nil
        }

        lockedDays = await PersistenceManager.shared.listeningGoal.historicalDays(connectionID: connectionID)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        StatisticsView(connectionID: "preview")
    }
    .previewEnvironment()
}

#Preview("Reading Goal Calendar") {
    let calendar = Calendar.current
    let target: TimeInterval = 30 * 60
    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now

    // Spread a mix of hit / partial / missed days across the current month so
    // every DayCell state (filled, faded, empty, today ring) is visible.
    let days: [Date: Double] = (0..<calendar.component(.day, from: .now)).reduce(into: [:]) { result, offset in
        guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { return }
        let seconds: TimeInterval
        switch offset % 3 {
        case 0: seconds = target + 600   // hit
        case 1: seconds = target * 0.4   // partial
        default: seconds = 0             // miss
        }
        result[calendar.startOfDay(for: date)] = seconds
    }

    return ReadingGoalCalendar(days: days, targetSeconds: target)
        .padding()
        .previewEnvironment()
}
#endif
