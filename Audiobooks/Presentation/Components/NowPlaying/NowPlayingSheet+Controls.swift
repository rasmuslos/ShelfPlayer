//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI

extension NowPlayingSheet {
    struct Controls: View {
        @Binding var playing: Bool
        
        @State var duration: Double = AudioPlayer.shared.getDuration()
        @State var currentTime: Double = AudioPlayer.shared.getCurrentTime()
        @State var playedPercentage: Double = (AudioPlayer.shared.getCurrentTime() / AudioPlayer.shared.getDuration()) * 100
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: $playedPercentage, dragging: .constant(false), onEnded: {
                        AudioPlayer.shared.seek(to: duration * (playedPercentage / 100))
                    })
                    .padding(.vertical, 10)
                    
                    HStack {
                        Text(currentTime.hoursMinutesSecondsString())
                        Spacer()
                        
                        Text((duration - currentTime).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)) + Text(" left")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                        
                        Spacer()
                        Text(duration.hoursMinutesSecondsString())
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                HStack {
                    Group {
                        Button {
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getCurrentTime() - 30)
                        } label: {
                            Image(systemName: "gobackward.30")
                        }
                        Button {
                            AudioPlayer.shared.setPlaying(!AudioPlayer.shared.isPlaying())
                        } label: {
                            Image(systemName: playing ? "pause.fill" : "play.fill")
                                .frame(height: 50)
                                .font(.system(size: 47))
                                .padding(.horizontal, 50)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        Button {
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getCurrentTime() + 30)
                        } label: {
                            Image(systemName: "goforward.30")
                        }
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                }
                .padding(.top, 30)
                .padding(.bottom, 60)
                
                VolumeSlider()
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.currentTimeChangedNotification), perform: { _ in
                withAnimation {
                    duration = AudioPlayer.shared.getDuration()
                    currentTime = AudioPlayer.shared.getCurrentTime()
                    playedPercentage = (currentTime / duration) * 100
                }
            })
        }
    }
}
