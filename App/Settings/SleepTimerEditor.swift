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

    @State private var hourOne: Int = 0
    @State private var minuteOne: Int = 0
    @State private var minuteTwo: Int = 0

    @State private var notifyError = false

    @ViewBuilder
    func row(index: Int) -> some View {
        Text(sleepTimerIntervals[index], format: .duration(unitsStyle: .full, allowedUnits: [.hour, .minute]))
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
                HStack {
                    Picker("preferences.sleepTimer.hours", selection: $hourOne) {
                        ForEach(0..<10) { hour in
                            Text(hour, format: .number)
                        }
                    }

                    Text(verbatim: ":")

                    Picker("preferences.sleepTimer.minutes", selection: $minuteTwo) {
                        ForEach(0..<7) { minute in
                            Text(minute, format: .number)
                        }
                    }
                    .accessibilityLabel("preferences.sleepTimer.minutes.tens")
                    Picker("preferences.sleepTimer.minutes", selection: $minuteOne) {
                        ForEach(0..<10) { minute in
                            Text(minute, format: .number)
                        }
                    }
                    .accessibilityLabel("preferences.sleepTimer.minutes.ones")
                }
                .pickerStyle(.wheel)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    0
                }

                Button("preferences.sleepTimer.add", systemImage: "plus") {
                    let time = Double(minuteOne) * 60 + Double(minuteTwo) * 60 * 10 + Double(hourOne) * 60 * 60

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
                        ForEach(sleepTimerIntervals, id: \.hashValue) {
                            Text($0, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute]))
                                .tag($0)
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
