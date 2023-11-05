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
        
        @State var buffering = AudioPlayer.shared.buffering
        @State var duration = AudioPlayer.shared.getChapterDuration()
        @State var currentTime = AudioPlayer.shared.getChapterCurrentTime()
        @State var playedPercentage = (AudioPlayer.shared.getChapterCurrentTime() / AudioPlayer.shared.getChapterDuration()) * 100
        
        @State var skipBackwardsInterval = UserDefaults.standard.integer(forKey: "skipBackwardsInterval")
        @State var skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: $playedPercentage, dragging: .constant(false), onEnded: {
                        AudioPlayer.shared.seek(to: duration * (playedPercentage / 100), includeChapterOffset: true)
                    })
                    .padding(.vertical, 10)
                    
                    HStack {
                        Group {
                            if buffering {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Text(currentTime.hoursMinutesSecondsString())
                            }
                        }
                        .frame(width: 65, alignment: .leading)
                        Spacer()
                        
                        Group {
                            if let chapter = AudioPlayer.shared.getChapter() {
                                Text(chapter.title)
                            } else {
                                Text((duration - currentTime).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)) + Text(verbatim: " ") + Text("time.left")
                            }
                        }
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                        Text(duration.hoursMinutesSecondsString())
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                HStack {
                    Group {
                        Button {
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getCurrentTime() - Double(skipBackwardsInterval))
                        } label: {
                            Image(systemName: "gobackward.\(skipBackwardsInterval)")
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
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getCurrentTime() + Double(skipForwardsInterval))
                        } label: {
                            Image(systemName: "goforward.\(skipForwardsInterval)")
                        }
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                }
                .padding(.vertical, 35)
                
                VolumeSlider()
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.currentTimeChangedNotification), perform: { _ in
                withAnimation {
                    buffering = AudioPlayer.shared.buffering
                }
                
                duration = AudioPlayer.shared.getChapterDuration()
                currentTime = AudioPlayer.shared.getChapterCurrentTime()
                playedPercentage = (currentTime / duration) * 100
            })
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification), perform: { _ in
                withAnimation {
                    skipBackwardsInterval = UserDefaults.standard.integer(forKey: "skipBackwardsInterval")
                    skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
                }
            })
        }
    }
}
