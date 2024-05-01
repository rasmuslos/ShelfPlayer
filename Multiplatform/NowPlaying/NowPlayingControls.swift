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

struct NowPlayingControls: View {
    @Default(.skipForwardsInterval) private var skipForwardsInterval
    @Default(.skipBackwardsInterval) private var skipBackwardsInterval
    
    let namespace: Namespace.ID
    let compact: Bool
    
    @Binding var controlsDragging: Bool
    
    @State private var seekDragging = false
    @State private var volumeDragging = false
    @State private var draggedPercentage = 0.0
    
    @State private var animateBackwards = false
    @State private var animateForwards = false
    
    private var playedPercentage: Double {
        (AudioPlayer.shared.currentTime / AudioPlayer.shared.duration) * 100
    }
    
    var body: some View {
        VStack {
            VStack {
                Slider(
                    percentage: .init(get: { seekDragging ? draggedPercentage : playedPercentage }, set: {
                        if Defaults[.lockSeekBar] {
                            return
                        }
                        
                        draggedPercentage = $0
                        AudioPlayer.shared.seek(to: AudioPlayer.shared.duration * (draggedPercentage / 100), includeChapterOffset: true)
                    }),
                    dragging: .init(get: { seekDragging }, set: {
                        seekDragging = $0
                        controlsDragging = $0
                    }))
                .frame(height: 10)
                .padding(.bottom, compact ? 3 : 10)
                
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
                        if seekDragging {
                            Text(formatRemainingTime(AudioPlayer.shared.duration - AudioPlayer.shared.duration * (playedPercentage / 100)))
                        } else if let chapter = AudioPlayer.shared.chapter {
                            Text(chapter.title)
                                .animation(.easeInOut, value: chapter.title)
                                .matchedGeometryEffect(id: "chapter", in: namespace, properties: .frame, anchor: .top)
                        } else {
                            Text(formatRemainingTime(AudioPlayer.shared.adjustedTimeLeft))
                        }
                    }
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                    .padding(.vertical, compact ? 2 : 4)
                    
                    Spacer()
                    Text(AudioPlayer.shared.duration.hoursMinutesSecondsString())
                        .frame(width: 65, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            HStack {
                Group {
                    Spacer()
                    
                    Label("backwards", systemImage: "gobackward.\(skipBackwardsInterval)")
                        .labelStyle(.iconOnly)
                        .symbolEffect(.bounce, value: animateBackwards)
                        .sensoryFeedback(.decrease, trigger: animateBackwards)
                        .font(.system(size: 30))
                        .frame(width: 50, height:50)
                        .gesture(TapGesture()
                            .onEnded { _ in
                                animateBackwards.toggle()
                                AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() - Double(skipBackwardsInterval))
                            })
                        .gesture(LongPressGesture()
                            .onEnded { _ in
                                if AudioPlayer.shared.chapter != nil {
                                    AudioPlayer.shared.seek(to: 0, includeChapterOffset: true)
                                }
                            })
                    
                    Spacer()
                    
                    Button {
                        AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                    } label: {
                        Label("playback.toggle", systemImage: AudioPlayer.shared.playing ? "pause.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                            .frame(width: 50, height:50)
                            .font(.system(size: 47))
                            .padding(.horizontal, 50)
                            .contentTransition(.symbolEffect(.replace.downUp))
                    }
                    .sensoryFeedback(.selection, trigger: AudioPlayer.shared.playing)
                    .frame(width: 60)
                    
                    Spacer()
                    
                    Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                        .labelStyle(.iconOnly)
                        .symbolEffect(.bounce, value: animateForwards)
                        .sensoryFeedback(.increase, trigger: animateForwards)
                        .font(.system(size: 30))
                        .frame(width: 50, height:50)
                        .gesture(TapGesture()
                            .onEnded { _ in
                                animateForwards.toggle()
                                AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                            })
                        .gesture(LongPressGesture()
                            .onEnded { _ in
                                if AudioPlayer.shared.chapter != nil {
                                    AudioPlayer.shared.seek(to: AudioPlayer.shared.duration, includeChapterOffset: true)
                                }
                            })
                        .popoverTip(LongPressSeekTip())
                    
                    Spacer()
                }
                .foregroundStyle(.primary)
            }
            .padding(.top, compact ? 20 : 35)
            .padding(.bottom, compact ? 40 : 65)
            
            VolumeSlider(dragging: .init(get: { volumeDragging }, set: {
                volumeDragging = $0
                controlsDragging = $0
            }))
            VolumeView()
                .frame(width: 0, height: 0)
        }
    }
}

extension NowPlayingControls {
    func formatRemainingTime(_ time: Double) -> String {
        time.hoursMinutesSecondsString(includeSeconds: false, includeLabels: true) + " " + String(localized: "time.left")
    }
}

extension NowPlayingControls {
    struct VolumeView: UIViewRepresentable {
        func makeUIView(context: Context) -> MPVolumeView {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            volumeView.alpha = 0.001
            
            return volumeView
        }
        
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
    }
}
