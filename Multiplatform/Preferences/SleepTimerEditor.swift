//
//  SleepTimerEditor.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import ShelfPlayback

struct SleepTimerEditor: View {
    @Default(.sleepTimerIntervals) private var sleepTimerIntervals
    @Default(.sleepTimerExtendInterval) private var sleepTimerExtendInterval
    @Default(.sleepTimerExtendChapterAmount) private var sleepTimerExtendChapterAmount
    @Default(.extendSleepTimerByPreviousSetting) private var extendSleepTimerByPreviousSetting
    
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
                    Picker("preferences.sleepTimer.minutes", selection: $minuteOne) {
                        ForEach(0..<10) { minute in
                            Text(minute, format: .number)
                        }
                    }
                }
                .pickerStyle(.wheel)
                
                Button("preferences.sleepTimer.add", systemImage: "plus") {
                    let time = Double(minuteOne) * 60 + Double(minuteTwo) * 60 * 10 + Double(hourOne) * 60 * 60
                    
                    guard time > 0 && !sleepTimerIntervals.contains(time) else {
                        notifyError.toggle()
                        return
                    }
                    
                    sleepTimerIntervals.append(time)
                    sleepTimerIntervals.sort()
                }
            }
            
            Section("sleepTimer.extend") {
                Toggle("sleepTimer.extend.usingPreviousSetting", isOn: $extendSleepTimerByPreviousSetting)
                
                Group {
                    Picker("sleepTimer.extend.interval", selection: $sleepTimerExtendInterval) {
                        ForEach(sleepTimerIntervals, id: \.hashValue) {
                            Text($0, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute]))
                                .tag($0)
                        }
                    }
                    
                    Stepper("sleepTimer.extend.chapters \(sleepTimerExtendChapterAmount)", value: $sleepTimerExtendChapterAmount, in: ClosedRange(uncheckedBounds: (1, 42)))
                }
                .disabled(extendSleepTimerByPreviousSetting)
            }
            
            Section {
                Button("action.reset", role: .destructive) {
                    Defaults.reset([.sleepTimerIntervals, .sleepTimerExtendInterval, .sleepTimerExtendChapterAmount])
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("perferences.sleepTimer")
        .hapticFeedback(.error, trigger: notifyError)
    }
}

#Preview {
    SleepTimerEditor()
}
