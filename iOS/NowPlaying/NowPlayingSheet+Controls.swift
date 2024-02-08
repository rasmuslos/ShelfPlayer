//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import Defaults
import MediaPlayer
import SPBase
import SPPlayback

extension NowPlayingSheet {
    struct Controls: View {
        @Default(.skipForwardsInterval) var skipForwardsInterval
        @Default(.skipBackwardsInterval) var skipBackwardsInterval
        
        @State private var dragging = false
        @State private var draggedPercentage = 0.0
        
        @State private var animateBackwards = false
        @State private var animateForwards = false
        
        private var playedPercentage: Double {
            (AudioPlayer.shared.currentTime / AudioPlayer.shared.duration) * 100
        }
        
        var body: some View {
            VStack {
                VStack {
                    Slider(percentage: .init(get: { dragging ? draggedPercentage : playedPercentage }, set: { draggedPercentage = $0 }), dragging: $dragging, onEnded: {
                        AudioPlayer.shared.seek(to: AudioPlayer.shared.duration * (draggedPercentage / 100), includeChapterOffset: true)
                    })
                    .frame(height: 10)
                    .padding(.vertical, 10)
                    
                    HStack {
                        Group {
                            if AudioPlayer.shared.buffering {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Text(AudioPlayer.shared.currentTime.hoursMinutesSecondsString())
                            }
                        }
                        .frame(width: 65, alignment: .leading)
                        Spacer()
                        
                        Group {
                            if dragging {
                                Text(formatRemainingTime(AudioPlayer.shared.duration - AudioPlayer.shared.duration * (playedPercentage / 100)))
                            } else if let chapter = AudioPlayer.shared.chapter {
                                Text(chapter.title)
                                    .animation(.easeInOut, value: chapter.title)
                            } else {
                                Text(formatRemainingTime(AudioPlayer.shared.duration - AudioPlayer.shared.currentTime))
                            }
                        }
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                        
                        Spacer()
                        Text(AudioPlayer.shared.duration.hoursMinutesSecondsString())
                            .frame(width: 65, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, -10)
                
                HStack {
                    Spacer()
                    
                    Group {
                        Button {
                            animateBackwards.toggle()
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() - Double(skipBackwardsInterval))
                        } label: {
                            Image(systemName: "gobackward.\(skipBackwardsInterval)")
                                .symbolEffect(.bounce, value: animateBackwards)
                                .frame(width: 60)
                        }
                        
                        Spacer()
                        
                        Button {
                            AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                        } label: {
                            Image(systemName: AudioPlayer.shared.playing ? "pause.fill" : "play.fill")
                                .frame(height: 50)
                                .font(.system(size: 47))
                                .padding(.horizontal, 50)
                                .contentTransition(.symbolEffect(.replace.downUp))
                        }
                        .sensoryFeedback(.selection, trigger: AudioPlayer.shared.playing)
                        .frame(width: 60)
                        
                        Spacer()
                        
                        Button {
                            animateForwards.toggle()
                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                        } label: {
                            Image(systemName: "goforward.\(skipForwardsInterval)")
                                .symbolEffect(.bounce, value: animateForwards)
                        }
                        .frame(width: 60)
                    }
                    .font(.system(size: 34))
                    .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 57)
                
                VolumeSlider()
                    .frame(height: 10)
                VolumeView()
                    .frame(width: 0, height: 0)
            }
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
