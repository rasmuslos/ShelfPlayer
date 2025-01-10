//
//  EpisodePlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation
import SPPersistence
import SPPlayback

internal struct EpisodePlayButton: View {
    // @Environment(NowPlaying.ViewModel.self) private var nowPlayingViewModel
    @Environment(\.library) private var library
    
    private let viewModel: EpisodePlayButtonViewModel
    
    @MainActor
    init(episode: Episode, loading: Binding<Bool>, highlighted: Bool = false) {
        viewModel = .init(episode: episode, loading: loading, highlighted: highlighted)
    }
    
    var body: some View {
        Button {
            /*
            if nowPlayingViewModel.item == viewModel.episode {
                AudioPlayer.shared.playing.toggle()
                return
            }
             */
            
            viewModel.play()
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
        .clipShape(.rect(cornerRadius: .infinity))
        .modifier(ButtonHoverEffectModifier(cornerRadius: .infinity, hoverEffect: .lift))
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
    }
}

private struct ButtonText: View {
    // @Environment(NowPlaying.ViewModel.self) private var nowPlayingViewModel
    @Environment(EpisodePlayButtonViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var isPlaying: Bool {
        // nowPlayingViewModel.item == viewModel.episode
        false
    }
    
    private var label: String {
        /*
        if viewModel.progressEntity.isFinished {
            return String(localized: "listen.again")
        } else if viewModel.progressEntity.progress <= 0 {
            return viewModel.episode.duration.formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute], maximumUnitCount: 1))
        } else if isPlaying, nowPlayingViewModel.itemDuration > 0 {
            return (nowPlayingViewModel.itemDuration - nowPlayingViewModel.itemCurrentTime)
                .formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
        } else {
            return (viewModel.progressEntity.duration - viewModel.progressEntity.currentTime)
                .formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
        }
         */
        ""
    }
    private var icon: String {
        /*
        if isPlaying && nowPlayingViewModel.playing {
            return "pause.fill"
        }
         */
        
        return "play.fill"
    }
    
    private var progressVisible: Bool {
        // isPlaying || (viewModel.progressEntity.progress > 0 && viewModel.progressEntity.progress < 1)
        false
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Image(systemName: "play.fill")
                    .hidden()
                
                Image(systemName: icon)
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    .opacity(viewModel.loading.wrappedValue ? 0 : 1)
            }
            .overlay {
                if viewModel.loading.wrappedValue {
                    ProgressIndicator()
                }
            }
            .controlSize(.small)
            .padding(.trailing, 4)
            
            Rectangle()
                .fill(.gray.opacity(0.25))
                .overlay(alignment: .leading) {
                    Rectangle()
                        // .frame(width: progressVisible ? max(40 * viewModel.progressEntity.progress, 5) : 0)
                }
                .frame(width: progressVisible ? 40 : 0, height: 5)
                .clipShape(.rect(cornerRadius: .infinity))
                .padding(.leading, progressVisible ? 4 : 0)
                .padding(.trailing, progressVisible ? 8 : 0)
            
            Text(label)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))
        }
        .font(.caption2)
        .animation(.smooth, value: isPlaying)
        // .animation(.smooth, value: nowPlayingViewModel.playing)
        // .animation(.smooth, value: viewModel.progressEntity.progress)
    }
}

@Observable
private final class EpisodePlayButtonViewModel {
    let episode: Episode
    var library: Library?
    
    let highlighted: Bool
    
    var loading: Binding<Bool>
    var progressEntity: ProgressEntity?
    
    @MainActor
    init(episode: Episode, loading: Binding<Bool>, highlighted: Bool) {
        self.episode = episode
        self.loading = loading
        self.highlighted = highlighted
        
        // progressEntity = OfflineManager.shared.progressEntity(item: episode)
    }
    
    func play() {
        let withoutPlaybackSession: Bool
        
        if let library {
            // for some inexplicable reason library is nil if highlighted it set to true
            // i have no idea why, maybe i will use one of my code level assistance credits for this
            // but only when you use the release configuration
            withoutPlaybackSession = library.type == .offline
        } else {
            withoutPlaybackSession = false
        }
        
        Task {
            /*
            loading.wrappedValue = true
            try? await AudioPlayer.shared.play(episode, withoutPlaybackSession: withoutPlaybackSession)
            loading.wrappedValue = false
             */
        }
    }
}

#if DEBUG
#Preview {
    EpisodePlayButton(episode: Episode.fixture, loading: .constant(false))
}

#Preview {
    ZStack {
        Rectangle()
            .fill(.black)
        
        EpisodePlayButton(episode: Episode.fixture, loading: .constant(false), highlighted: true)
    }
}
#endif
