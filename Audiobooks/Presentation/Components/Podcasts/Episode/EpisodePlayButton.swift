//
//  EpisodePlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodePlayButton: View {
    let episode: Episode
    var highlighted: Bool = false
    
    @State var progress: OfflineProgress?
    @State var playState = PlayState.none
    
    var body: some View {
        Button {
            episode.startPlayback()
        } label: {
            HStack(spacing: 6) {
                if playState == .none {
                    Image(systemName: "play.fill")
                } else {
                    Image(systemName: playState == .playing ? "waveform" : "pause.fill")
                        .symbolEffect(.variableColor, isActive: playState == .playing)
                        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
                            withAnimation {
                                playState = AudioPlayer.shared.isPlaying() ? .playing : .pause
                            }
                        })
                }
                
                if let progress = progress {
                    if progress.progress >= 1 {
                        Text("100%")
                            .font(.caption.smallCaps())
                            .bold()
                    } else {
                        Rectangle()
                            .foregroundStyle(.ultraThickMaterial)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .frame(width: max(50 * progress.progress, 5))
                                    .foregroundStyle(.black)
                            }
                            .frame(width: 50, height: 7)
                            .clipShape(RoundedRectangle(cornerRadius: 10000))
                        
                        Text((progress.duration - progress.currentTime).numericTimeLeft())
                            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
                                checkPlaying()
                            })
                    }
                } else {
                    Text(episode.duration.numericTimeLeft())
                }
            }
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(highlighted ? .white : .secondary.opacity(0.25))
            .foregroundStyle(highlighted ? .black : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10000))
            .onAppear(perform: fetchProgress)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Helper

extension EpisodePlayButton {
    private func fetchProgress() {
        checkPlaying()
        
        Task.detached {
            let progress = await OfflineManager.shared.getProgress(item: episode)
            withAnimation {
                self.progress = progress
            }
        }
    }
}

// MARK: Playing

extension EpisodePlayButton {
    enum PlayState {
        case none
        case playing
        case pause
    }
    
    private func checkPlaying() {
        withAnimation {
            if episode == AudioPlayer.shared.item {
                playState = AudioPlayer.shared.isPlaying() ? .playing : .pause
            } else {
                playState = .none
            }
        }
    }
}

#Preview {
    EpisodePlayButton(episode: Episode.fixture)
}
