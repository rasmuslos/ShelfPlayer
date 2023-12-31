//
//  SleepTimerButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 27.10.23.
//

import SwiftUI
import ShelfPlayerKit

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
                    let hourSingular = String(localized: "sleep.hour.singular")
                    let hourPlural = String(localized: "sleep.hour.plural")
                    let minute = String(localized: "sleep.minute")
                    
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 2 * 60 * 60)
                    } label: {
                        Text(verbatim: "2 \(hourPlural)")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 1.5 * 60 * 60)
                    } label: {
                        Text(verbatim: "1 \(hourSingular) 30 \(minute)")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 1 * 60 * 60)
                    } label: {
                        Text(verbatim: "1 \(hourSingular)")
                    }
                    
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 45 * 60)
                    } label: {
                        Text(verbatim: "45 \(minute)")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 30 * 60)
                    } label: {
                        Text(verbatim: "30 \(minute)")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 15 * 60)
                    } label: {
                        Text(verbatim: "15 \(minute)")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 5 * 60)
                    } label: {
                        Text(verbatim: "5 \(minute)")
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
