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
    
    @MainActor
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
                if AudioPlayer.shared.item == viewModel.episode {
                    Image(systemName: AudioPlayer.shared.playing ? "waveform" : "pause.fill")
                        .symbolEffect(.variableColor.iterative, isActive: AudioPlayer.shared.playing)
                } else {
                    Image(systemName: "play.fill")
                }
                
                if viewModel.entity.progress > 0 {
                    if viewModel.entity.progress >= 1 {
                        Text("progress.completed")
                            .font(.caption.smallCaps())
                            .bold()
                    } else {
                        if viewModel.entity.progress > 0 {
                            Rectangle()
                                .foregroundStyle(.gray.opacity(0.25))
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: max(50 * viewModel.entity.progress, 5))
                                        .foregroundStyle(viewModel.highlighted ? .black : colorScheme == .light ? .black : .white)
                                }
                                .frame(width: 50, height: 7)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        
                        Text((viewModel.entity.duration - viewModel.entity.currentTime).numericTimeLeft())
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
    
    var entity: OfflineProgress
    
    @MainActor
    init(episode: Episode, highlighted: Bool) {
        self.episode = episode
        self.highlighted = highlighted
        
        entity = OfflineManager.shared.requireProgressEntity(item: episode)
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
