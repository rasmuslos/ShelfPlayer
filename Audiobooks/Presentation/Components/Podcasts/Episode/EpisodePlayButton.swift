//
//  EpisodePlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodePlayButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    let episode: Episode
    var highlighted: Bool = false
    
    @State var progress: OfflineProgress?
    @State var playing: Bool? = nil
    
    var body: some View {
        Button {
            episode.startPlayback()
        } label: {
            HStack(spacing: 6) {
                if let playing = playing {
                    Image(systemName: playing == true ? "waveform" : "pause.fill")
                        .symbolEffect(.variableColor.iterative, isActive: playing == true)
                        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
                            withAnimation {
                                self.playing = AudioPlayer.shared.isPlaying()
                            }
                        })
                } else {
                    Image(systemName: "play.fill")
                }
                
                if let progress = progress {
                    if progress.progress >= 1 {
                        Text("100%")
                            .font(.caption.smallCaps())
                            .bold()
                    } else {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.25))
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .frame(width: max(50 * progress.progress, 5))
                                    .foregroundStyle(highlighted ? .black : colorScheme == .light ? .black : .white)
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
    
    private func checkPlaying() {
        withAnimation {
            if episode == AudioPlayer.shared.item {
                playing = AudioPlayer.shared.isPlaying()
            } else {
                playing = nil
            }
        }
    }
}

#Preview {
    EpisodePlayButton(episode: Episode.fixture)
}
