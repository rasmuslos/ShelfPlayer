//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import Defaults
import MediaPlayer
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    struct Controls: View {
        @Environment(ViewModel.self) private var viewModel
        
        let compact: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                ProgressSlider(compact: compact)
                ControlButtons(compact: compact)
                
                VolumeSlider(dragging: .init(get: { viewModel.volumeDragging }, set: { viewModel.volumeDragging = $0; viewModel.controlsDragging = $0 }))
                VolumePicker()
                    .hidden()
                    .frame(height: 0)
            }
        }
    }
}

private struct ProgressSlider: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let compact: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            NowPlaying.Slider(percentage: .init(get: { viewModel.displayedProgress }, set: {
                if Defaults[.lockSeekBar] {
                    return
                }
                
                viewModel.setPosition(percentage: $0)
            }), dragging: .init(get: { viewModel.seekDragging }, set: { viewModel.seekDragging = $0; viewModel.controlsDragging = $0 }))
            .padding(.bottom, compact ? 2 : 4)
            
            HStack(spacing: 0) {
                Group {
                    if viewModel.buffering {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(.primary)
                    } else {
                        Text(viewModel.chapterCurrentTime, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                            .contentTransition(.numericText())
                    }
                }
                .frame(width: 64, alignment: .leading)
                
                Spacer()
                
                Group {
                    if viewModel.seekDragging && viewModel.chapter != nil {
                        Text(viewModel.itemCurrentTime, format: .duration(unitsStyle: .abbreviated))
                            .contentTransition(.numericText())
                    } else if let chapter = AudioPlayer.shared.chapter {
                        Text(chapter.title)
                            .animation(.easeInOut, value: chapter.title)
                    } else {
                        Text(viewModel.remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                            .contentTransition(.numericText())
                    }
                }
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .transition(.opacity)
                .padding(.vertical, compact ? 2 : 4)
                
                Spacer()
                
                Text(viewModel.chapterDuration, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                    .contentTransition(.numericText())
                    .frame(width: 64, alignment: .trailing)
            }
            .font(.footnote.smallCaps())
            .foregroundStyle(.secondary)
        }
    }
}

private struct ControlButtons: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let compact: Bool
    
    @ViewBuilder
    private var backwardsButton: some View {
        Label("backwards", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
            .labelStyle(.iconOnly)
            .modify {
                if #available(iOS 18, *) {
                    $0
                        .symbolEffect(.rotate.counterClockwise.byLayer, value: viewModel.notifyBackwards)
                } else {
                    $0
                        .symbolEffect(.bounce, value: viewModel.notifyBackwards)
                }
            }
            .font(.system(size: 32))
            .modifier(ButtonHoverEffectModifier())
            .gesture(TapGesture().onEnded { _ in
                AudioPlayer.shared.skipBackwards()
            })
            .gesture(LongPressGesture().onEnded { _ in
                AudioPlayer.shared.chapterCurrentTime = 0
            })
    }
    
    @ViewBuilder
    private var playButton: some View {
        Button {
            AudioPlayer.shared.playing.toggle()
        } label: {
            Label("playback.toggle", systemImage: viewModel.playing ? "pause.fill" : "play.fill")
                .labelStyle(.iconOnly)
                .contentTransition(.symbolEffect(.replace.byLayer.downUp))
        }
        .buttonStyle(.plain)
        .frame(width: 52, height: 52)
        .font(.system(size: 48))
        .modifier(ButtonHoverEffectModifier())
    }
    
    @ViewBuilder
    private var forwardButton: some View {
        Label("forwards", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
            .labelStyle(.iconOnly)
            .modify {
                if #available(iOS 18, *) {
                    $0
                        .symbolEffect(.rotate.clockwise.byLayer, value: viewModel.notifyForwards)
                } else {
                    $0
                        .symbolEffect(.bounce, value: viewModel.notifyForwards)
                }
            }
            .font(.system(size: 32))
            .modifier(ButtonHoverEffectModifier())
            .gesture(TapGesture().onEnded { _ in
                AudioPlayer.shared.skipForwards()
            })
            .gesture(LongPressGesture().onEnded { _ in
                AudioPlayer.shared.chapterCurrentTime = AudioPlayer.shared.chapterDuration
            })
    }
    
    var body: some View {
        if !compact {
            LazyVGrid(columns: [.init(), .init(), .init()]) {
                backwardsButton
                playButton
                forwardButton
            }
            .padding(.top, 60)
            .padding(.bottom, 80)
            .padding(.horizontal, 20)
            .frame(maxHeight: 160)
            .border(.green)
        } else {
            HStack(spacing: 0) {
                backwardsButton
                playButton
                    .padding(.horizontal, 50)
                forwardButton
            }
            .foregroundStyle(.primary)
            .padding(.top, 44)
            .padding(.bottom, 68)
        }
    }
}

private struct VolumePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: CGRect.zero)
        return volumeView
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
