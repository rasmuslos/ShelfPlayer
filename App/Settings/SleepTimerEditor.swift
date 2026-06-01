//
//  SleepTimerEditor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import ShelfPlayback

struct SleepTimerEditor: View {
    private var settings: AppSettings { .shared }

    @State private var sleepTimerIntervals: [Double] = AppSettings.shared.sleepTimerIntervals
    @State private var sleepTimerExtendInterval: Double = AppSettings.shared.sleepTimerExtendInterval
    @State private var sleepTimerExtendChapterAmount: Int = AppSettings.shared.sleepTimerExtendChapterAmount
    @State private var extendSleepTimerByPreviousSetting: Bool = AppSettings.shared.extendSleepTimerByPreviousSetting

    @State private var hours: Int = 0
    @State private var minutes: Int = 0

    @State private var notifyError = false

    /// Anything one hour or longer renders as "H:MM" (e.g. "1:30", "3:11"). Sub-hour
    /// intervals keep the prose unit format ("30 minutes").
    @ViewBuilder
    func row(index: Int) -> some View {
        let interval = sleepTimerIntervals[index]
        let totalMinutes = Int(interval / 60)
        if totalMinutes >= 60 {
            Text(verbatim: String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60))
        } else {
            Text(interval, format: .duration(unitsStyle: .full, allowedUnits: [.hour, .minute]))
        }
    }

    var body: some View {
        List {
            SettingsPageHeader(title: "settings.sleepTimer.intervals", systemImage: "moon.zzz.fill", color: .indigo)

            Section {
                ForEach(Array(sleepTimerIntervals.enumerated()), id: \.element.hashValue) {
                    row(index: $0.offset)
                }
                .onDelete {
                    for index in $0 {
                        sleepTimerIntervals.remove(at: index)

                        if sleepTimerIntervals.isEmpty {
                            sleepTimerIntervals.append(30 * 60)
                        }
                    }
                    save()
                }
            }

            Section {
                HStack(spacing: 0) {
                    Picker("preferences.sleepTimer.hours", selection: $hours) {
                        ForEach(0..<10) { hour in
                            Text(hour, format: .number)
                        }
                    }

                    Text(verbatim: ":")

                    Picker("preferences.sleepTimer.minutes", selection: $minutes) {
                        ForEach(0..<60) { minute in
                            Text(String(format: "%02d", minute))
                        }
                    }
                }
                .pickerStyle(.wheel)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    0
                }

                Button("preferences.sleepTimer.add", systemImage: "plus") {
                    let time = Double(hours) * 3600 + Double(minutes) * 60

                    guard time > 0 && !sleepTimerIntervals.contains(time) else {
                        notifyError.toggle()
                        return
                    }

                    sleepTimerIntervals.append(time)
                    sleepTimerIntervals.sort()
                    save()
                }
            }

            Section("sleepTimer.extend") {
                Toggle("sleepTimer.extend.usingPreviousSetting", isOn: $extendSleepTimerByPreviousSetting)
                    .onChange(of: extendSleepTimerByPreviousSetting) { settings.extendSleepTimerByPreviousSetting = extendSleepTimerByPreviousSetting }

                Group {
                    Picker("sleepTimer.extend.interval", selection: $sleepTimerExtendInterval) {
                        ForEach(sleepTimerIntervals, id: \.self) { interval in
                            let totalMinutes = Int(interval / 60)
                            if totalMinutes >= 60 {
                                Text(verbatim: String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60))
                                    .tag(interval)
                            } else {
                                Text(interval, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute]))
                                    .tag(interval)
                            }
                        }
                    }
                    .onChange(of: sleepTimerExtendInterval) { settings.sleepTimerExtendInterval = sleepTimerExtendInterval }

                    Stepper("sleepTimer.extend.chapters \(sleepTimerExtendChapterAmount)", value: $sleepTimerExtendChapterAmount, in: ClosedRange(uncheckedBounds: (1, 42)))
                        .onChange(of: sleepTimerExtendChapterAmount) { settings.sleepTimerExtendChapterAmount = sleepTimerExtendChapterAmount }
                }
                .disabled(extendSleepTimerByPreviousSetting)
            }

            Section {
                Button("action.reset", role: .destructive) {
                    sleepTimerIntervals = [5, 10, 15, 20, 25, 30, 45, 60, 75, 90].map { Double($0) * 60 }
                    sleepTimerExtendInterval = 1200
                    sleepTimerExtendChapterAmount = 1
                    extendSleepTimerByPreviousSetting = true
                    save()
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("perferences.sleepTimer")
        .navigationBarTitleDisplayMode(.inline)
        .hapticFeedback(.error, trigger: notifyError)
    }

    private func save() {
        settings.sleepTimerIntervals = sleepTimerIntervals
        settings.sleepTimerExtendInterval = sleepTimerExtendInterval
        settings.sleepTimerExtendChapterAmount = sleepTimerExtendChapterAmount
    }
}

#Preview {
    SleepTimerEditor()
}
