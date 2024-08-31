//
//  EpisodePlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation
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
            
        } label: {
            ButtonText()
                .opacity(viewModel.highlighted ? 0 : 1)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(viewModel.highlighted ? .white : .secondary.opacity(0.25))
                .foregroundStyle(viewModel.highlighted ? .black : .primary)
                .reverseMask {
                    if viewModel.highlighted {
                        ButtonText()
                    }
                }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: .infinity))
        .modifier(ButtonHoverEffectModifier(cornerRadius: .infinity, hoverEffect: .lift))
        .id(viewModel.episode.id)
        .environment(viewModel)
    }
}

extension EpisodePlayButton {
    struct ButtonText: View {
        @Environment(\.colorScheme) var colorScheme
        @Environment(EpisodePlayButtonViewModel.self) var viewModel
        
        private var labelImage: String {
            if AudioPlayer.shared.item == viewModel.episode {
                return AudioPlayer.shared.playing ? "waveform" : "pause.fill"
            } else {
                return "play.fill"
            }
        }
        
        var body: some View {
            HStack(spacing: 6) {
                Label("playing", systemImage: labelImage)
                    .labelStyle(.iconOnly)
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform" && AudioPlayer.shared.playing)
                    .frame(width: 20, height: 15)
                
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
                                        .frame(width: max(40 * viewModel.entity.progress, 5))
                                        .foregroundStyle(viewModel.highlighted ? .black : colorScheme == .light ? .black : .white)
                                }
                                .frame(width: 40, height: 5)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        
                        Text("duration") // Text((viewModel.entity.duration - viewModel.entity.currentTime).numericTimeLeft())
                    }
                } else {
                    Text("duration") // Text(viewModel.episode.duration.numericTimeLeft())
                }
            }
            .font(.caption)
        }
    }
}

@Observable
final class EpisodePlayButtonViewModel {
    let episode: Episode
    let highlighted: Bool
    
    var entity: ItemProgress
    
    @MainActor
    init(episode: Episode, highlighted: Bool) {
        self.episode = episode
        self.highlighted = highlighted
        
        entity = OfflineManager.shared.progressEntity(item: episode)
    }
}

#if DEBUG
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
#endif
