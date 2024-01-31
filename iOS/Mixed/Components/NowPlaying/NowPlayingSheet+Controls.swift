//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import MediaPlayer
import SPBase
import SPPlayback

extension NowPlayingSheet {
    struct Controls: View {
        @Binding var playing: Bool
        @State var dragging = false
        
        @State var buffering = AudioPlayer.shared.buffering
        @State var duration = AudioPlayer.shared.getChapterDuration()
        @State var currentTime = AudioPlayer.shared.getChapterCurrentTime()
        @State var playedPercentage = (AudioPlayer.shared.getChapterCurrentTime() / AudioPlayer.shared.getChapterDuration()) * 100
        
        @State var skipBackwardsInterval = UserDefaults.standard.integer(forKey: "skipBackwardsInterval")
        @State var skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: currentTime.isFinite && !currentTime.isNaN ? $playedPercentage : .constant(0), dragging: $dragging, onEnded: {
                        AudioPlayer.shared.seek(to: duration * (playedPercentage / 100), includeChapterOffset: true)
                    })
                    .frame(height: 10)
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
                            if dragging {
                                Text(formatRemainingTime(duration - duration * (playedPercentage / 100)))
                            } else if let chapter = AudioPlayer.shared.getChapter() {
                                Text(chapter.title)
                                    .animation(.easeInOut, value: chapter.title)
                            } else {
                                Text(formatRemainingTime(duration - currentTime))
                            }
                        }
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                        
                        Spacer()
                        Text(duration.hoursMinutesSecondsString())
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, -10)
                
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
                .padding(.vertical, 45)
                
                VolumeSlider()
                    .frame(height: 10)
                VolumeView()
                    .frame(width: 0, height: 0)
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.currentTimeChangedNotification), perform: { _ in
                withAnimation {
                    buffering = AudioPlayer.shared.buffering
                }
                
                if !dragging {
                    duration = AudioPlayer.shared.getChapterDuration()
                    currentTime = AudioPlayer.shared.getChapterCurrentTime()
                    playedPercentage = (currentTime / duration) * 100
                }
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

extension NowPlayingSheet.Controls {
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}

extension NowPlayingSheet.Controls {
    func formatRemainingTime(_ time: Double) -> String {
        time.hoursMinutesSecondsString(includeSeconds: false, includeLabels: true) + " " + String(localized: "time.left")
    }
}
