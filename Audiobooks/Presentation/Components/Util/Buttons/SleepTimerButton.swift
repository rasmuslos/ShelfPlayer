//
//  SleepTimerButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 27.10.23.
//

import SwiftUI

struct SleepTimerButton: View {
    @State var remainingSleepTimerTime = AudioPlayer.shared.remainingSleepTimerTime
    
    var body: some View {
        Group {
            if let remainingSleepTimerTime = remainingSleepTimerTime {
                Menu {
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: remainingSleepTimerTime + 60)
                    } label: {
                        Label("Increase by one minute", systemImage: "plus")
                    }
                    Button {
                        let decreasedTime = remainingSleepTimerTime - 60
                        if decreasedTime <= 0 {
                            AudioPlayer.shared.setSleepTimer(duration: nil)
                        } else {
                            AudioPlayer.shared.setSleepTimer(duration: decreasedTime)
                        }
                    } label: {
                        Label("Decrease by one minute", systemImage: "minus")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: nil)
                    } label: {
                        Label("Clear sleep timer", systemImage: "moon.stars")
                    }
                } label: {
                    Text(remainingSleepTimerTime.numericTimeLeft())
                        .fontDesign(.rounded)
                }
            } else {
                Menu {
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 2 * 60 * 60)
                    } label: {
                        Text("2 hours")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 1.5 * 60 * 60)
                    } label: {
                        Text("1 hour 30 minutes")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 1 * 60 * 60)
                    } label: {
                        Text("1 hour")
                    }
                    
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 45 * 60)
                    } label: {
                        Text("45 minutes")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 30 * 60)
                    } label: {
                        Text("30 minutes")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 15 * 60)
                    } label: {
                        Text("15 minutes")
                    }
                    Button {
                        AudioPlayer.shared.setSleepTimer(duration: 5 * 60)
                    } label: {
                        Text("5 minutes")
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
