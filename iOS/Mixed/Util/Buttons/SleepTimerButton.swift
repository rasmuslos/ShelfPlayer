//
//  SleepTimerButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 27.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

struct SleepTimerButton: View {
    @State var remainingSleepTimerTime = AudioPlayer.shared.remainingSleepTimerTime
    
    var body: some View {
        Group {
            if let remainingSleepTimerTime = remainingSleepTimerTime {
                Menu {
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: remainingSleepTimerTime + 60)
                    } label: {
                        Label("sleep.increase", systemImage: "plus")
                    }
                    Button {
                        let decreasedTime = remainingSleepTimerTime - 60
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
            } else {
                Menu {
                    let durations = [120, 90, 60, 45, 30, 15, 5]
                    
                    ForEach(durations, id: \.self) { duration in
                        Button {
                            AudioPlayer.shared.setSleepTimer(duration: 2 * 60 * 60)
                        } label: {
                            Text("\(duration) sleep.minutes")
                        }
                    }
                } label: {
                    Image(systemName: "moon.zzz")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.sleepTimerChanged), perform: { _ in
            withAnimation {
                remainingSleepTimerTime = AudioPlayer.shared.remainingSleepTimerTime
            }
        })
    }
}

#Preview {
    SleepTimerButton()
}
