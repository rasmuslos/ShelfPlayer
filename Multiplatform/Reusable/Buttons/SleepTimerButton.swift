//
//  SleepTimerButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 27.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

internal struct SleepTimerButton: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    @Default(.customSleepTimer) private var customSleepTimer
    @Default(.sleepTimerAdjustment) private var sleepTimerAdjustment
    
    var body: some View {
        if let remainingSleepTime = viewModel.remainingSleepTime {
            Menu {
                ControlGroup {
                    Button {
                        SleepTimer.shared.expiresAt = DispatchTime.now().advanced(by: .seconds(Int(remainingSleepTime))).advanced(by: .seconds(Int(-sleepTimerAdjustment)))
                    } label: {
                        Label("decrease", systemImage: "minus")
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        SleepTimer.shared.expiresAt = DispatchTime.now().advanced(by: .seconds(Int(remainingSleepTime))).advanced(by: .seconds(Int(sleepTimerAdjustment)))
                    } label: {
                        Label("increase", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            } label: {
                Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                    .fixedSize()
                    .fontDesign(.rounded)
                    .contentTransition(.numericText(countsDown: true))
            } primaryAction: {
                SleepTimer.shared.expiresAt = nil
            }
            .menuActionDismissBehavior(.disabled)
        } else if viewModel.sleepTimerExpiresAtChapterEnd {
            Button {
                SleepTimer.shared.expiresAtChapterEnd = false
            } label: {
                Label("sleep.chapter", systemImage: "book.pages.fill")
                    .labelStyle(.iconOnly)
            }
        } else {
            Menu {
                ForEach([120, 90, 60, 45, 30, 15, 5].map { $0 * 60 }, id: \.self) { duration in
                    Button {
                        SleepTimer.shared.expiresAt = .now().advanced(by: .seconds(duration))
                    } label: {
                        Text(TimeInterval(duration), format: .duration(unitsStyle: .full, allowedUnits: [.minute]))
                    }
                }
                
                if customSleepTimer > 0 {
                    let duration = customSleepTimer * 60
                    
                    Divider()
                    
                    Button {
                        SleepTimer.shared.expiresAt = .now().advanced(by: .seconds(duration))
                    } label: {
                        Text(TimeInterval(duration), format: .duration(unitsStyle: .full, allowedUnits: [.minute]))
                    }
                }
                
                if viewModel.chapter != nil {
                    Divider()
                    
                    Button {
                        SleepTimer.shared.expiresAtChapterEnd = true
                    } label: {
                        Text("sleep.chapter")
                    }
                }
            } label: {
                Label("sleepTimer", systemImage: "moon.zzz")
            }
        }
    }
}
