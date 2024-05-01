//
//  SleepTimerButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 27.10.23.
//

import SwiftUI
import Defaults
import SPBase
import SPPlayback

struct SleepTimerButton: View {
    @Default(.customSleepTimer) private var customSleepTimer
    @Default(.sleepTimerAdjustment) var sleepTimerAdjustment
    
    var body: some View {
        Group {
            if let remainingSleepTimerTime = AudioPlayer.shared.remainingSleepTimerTime {
                Menu {
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: remainingSleepTimerTime + sleepTimerAdjustment)
                    } label: {
                        Label("sleep.increase", systemImage: "plus")
                    }
                    
                    Button {
                        let decreasedTime = remainingSleepTimerTime - sleepTimerAdjustment
                        if decreasedTime <= 0 {
                            AudioPlayer.shared.setSleepTimer(duration: nil)
                        } else {
                            AudioPlayer.shared.setSleepTimer(duration: decreasedTime)
                        }
                    } label: {
                        Label("sleep.decrease", systemImage: "minus")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: nil)
                    } label: {
                        Label("sleep.clear", systemImage: "moon.stars")
                    }
                } label: {
                    Text(remainingSleepTimerTime.numericTimeLeft())
                        .fontDesign(.rounded)
                }
                .menuActionDismissBehavior(.disabled)
            } else if AudioPlayer.shared.pauseAtEndOfChapter {
                Button {
                    AudioPlayer.shared.setSleepTimer(duration: nil)
                } label: {
                    Label("sleep.chapter", systemImage: "book.pages.fill")
                        .labelStyle(.iconOnly)
                }
            } else {
                Menu {
                    let durations = [120, 90, 60, 45, 30, 15, 5]
                    
                    ForEach(durations, id: \.self) { duration in
                        Button {
                            AudioPlayer.shared.setSleepTimer(duration: Double(duration) * 60)
                        } label: {
                            Text("\(duration) sleep.minutes")
                        }
                    }
                    
                    if customSleepTimer > 0 {
                        Divider()
                        
                        let value = Double(customSleepTimer) * 60
                        
                        Button {
                            AudioPlayer.shared.setSleepTimer(duration: value)
                        } label: {
                            Text(Date.now.addingTimeInterval(-value), style: .offset)
                        }
                    }
                    
                    if AudioPlayer.shared.chapter != nil {
                        Divider()
                        
                        Button {
                            AudioPlayer.shared.setSleepTimer(endOfChapter: true)
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
}

#Preview {
    SleepTimerButton()
}
