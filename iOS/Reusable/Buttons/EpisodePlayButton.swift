//
//  EpisodePlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct EpisodePlayButton: View {
    let viewModel: EpisodePlayButtonViewModel
    
    init(episode: Episode, highlighted: Bool = false) {
        viewModel = .init(episode: episode, highlighted: highlighted)
    }
    
    var body: some View {
        Button {
            viewModel.episode.startPlayback()
        } label: {
            ButtonText()
                .opacity(viewModel.highlighted ? 0 : 1)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(viewModel.highlighted ? .white : .secondary.opacity(0.25))
                .foregroundStyle(viewModel.highlighted ? .black : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10000))
                .reverseMask {
                    if viewModel.highlighted {
                        ButtonText()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: OfflineManager.progressCreatedNotification)) { _ in Task { await viewModel.fetchProgress() }}
                .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification)) { _ in viewModel.checkPlaying() }
                .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification)) { _ in viewModel.checkPlaying() }
                .task {
                    await viewModel.fetchProgress()
                    viewModel.checkPlaying()
                }
        }
        .buttonStyle(.plain)
        .id(viewModel.episode.id)
        .environment(viewModel)
    }
}

extension EpisodePlayButton {
    struct ButtonText: View {
        @Environment(\.colorScheme) var colorScheme
        @Environment(EpisodePlayButtonViewModel.self) var viewModel
        
        var body: some View {
            HStack(spacing: 6) {
                if let playing = viewModel.playing {
                    Image(systemName: playing == true ? "waveform" : "pause.fill")
                        .symbolEffect(.variableColor.iterative, isActive: playing == true)
                } else {
                    Image(systemName: "play.fill")
                }
                
                if let progress = viewModel.progress {
                    if progress.progress >= 1 {
                        Text("progress.completed")
                            .font(.caption.smallCaps())
                            .bold()
                    } else {
                        if progress.progress > 0 {
                            Rectangle()
                                .foregroundStyle(.gray.opacity(0.25))
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: max(50 * progress.progress, 5))
                                        .foregroundStyle(viewModel.highlighted ? .black : colorScheme == .light ? .black : .white)
                                }
                                .frame(width: 50, height: 7)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        
                        Text((progress.duration - progress.currentTime).numericTimeLeft())
                    }
                } else {
                    Text(viewModel.episode.duration.numericTimeLeft())
                }
            }
            .font(.caption)
        }
    }
}

@Observable
class EpisodePlayButtonViewModel {
    let episode: Episode
    let highlighted: Bool
    
    var playing: Bool?
    var progress: OfflineProgress?
    
    init(episode: Episode, highlighted: Bool) {
        self.episode = episode
        self.highlighted = highlighted
    }
    
    func fetchProgress() async {
        let progress = await OfflineManager.shared.getProgressEntity(item: episode)
        withAnimation {
            self.progress = progress
        }
    }
    func checkPlaying() {
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
    Rectangle()
        .foregroundStyle(.black)
        .overlay {
            EpisodePlayButton(episode: Episode.fixture)
        }
}

#Preview {
    Rectangle()
        .foregroundStyle(.black)
        .overlay {
            EpisodePlayButton(episode: Episode.fixture, highlighted: true)
        }
}
