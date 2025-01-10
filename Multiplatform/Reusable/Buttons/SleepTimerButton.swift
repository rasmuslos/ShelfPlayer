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

/*
internal struct SleepTimerButton: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    @Default(.customSleepTimer) private var customSleepTimer
    @Default(.sleepTimerAdjustment) private var sleepTimerAdjustment
    
    @ViewBuilder
    private var clearButton: some View {
        Button {
            /*
            SleepTimer.shared.expiresAt = nil
            SleepTimer.shared.expiresAtChapterEnd = nil
             */
        } label: {
            Label("sleep.clear", systemImage: "trash")
                .labelStyle(.iconOnly)
        }
    }
    
    var body: some View {
        Menu {
            if let remainingSleepTime = viewModel.remainingSleepTime {
                ControlGroup {
                    Button {
                        // SleepTimer.shared.expiresAt = DispatchTime.now().advanced(by: .seconds(Int(remainingSleepTime))).advanced(by: .seconds(Int(-sleepTimerAdjustment)))
                    } label: {
                        Label("decrease", systemImage: "minus")
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        // SleepTimer.shared.expiresAt = DispatchTime.now().advanced(by: .seconds(Int(remainingSleepTime))).advanced(by: .seconds(Int(sleepTimerAdjustment)))
                    } label: {
                        Label("increase", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
                
                clearButton
            } else if let sleepTimerExpiresAtChapterEnd = viewModel.sleepTimerExpiresAtChapterEnd {
                ControlGroup {
                    Button {
                        // SleepTimer.shared.expiresAtChapterEnd? -= 1
                    } label: {
                        Label("decrease", systemImage: "minus")
                            .labelStyle(.iconOnly)
                    }
                    
                    Text(String(sleepTimerExpiresAtChapterEnd))
                    
                    Button {
                        // SleepTimer.shared.expiresAtChapterEnd? += 1
                    } label: {
                        Label("increase", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
                
                clearButton
            } else {
                ForEach([120, 90, 60, 45, 30, 15, 5].map { $0 * 60 }, id: \.self) { duration in
                    Button {
                        // SleepTimer.shared.expiresAt = .now().advanced(by: .seconds(duration))
                    } label: {
                        Text(TimeInterval(duration), format: .duration(unitsStyle: .full, allowedUnits: [.minute]))
                    }
                }
                
                if customSleepTimer > 0 {
                    let duration = customSleepTimer * 60
                    
                    Divider()
                    
                    Button {
                        // SleepTimer.shared.expiresAt = .now().advanced(by: .seconds(duration))
                    } label: {
                        Text(TimeInterval(duration), format: .duration(unitsStyle: .full, allowedUnits: [.minute]))
                    }
                }
                
                if viewModel.chapter != nil {
                    Divider()
                    
                    Button {
                        // SleepTimer.shared.expiresAtChapterEnd = 1
                    } label: {
                        Text("sleep.chapter")
                    }
                }
            }
        } label: {
            if let remainingSleepTime = viewModel.remainingSleepTime {
                Text(remainingSleepTime, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .second], maximumUnitCount: 1))
                    .fixedSize()
                    .fontDesign(.rounded)
                    .contentTransition(.numericText(countsDown: true))
            } else if viewModel.sleepTimerExpiresAtChapterEnd != nil {
                Label("sleep.chapter", systemImage: "book.pages.fill")
                    .labelStyle(.iconOnly)
            } else {
                Label("sleepTimer", systemImage: "moon.zzz")
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
}
*/
