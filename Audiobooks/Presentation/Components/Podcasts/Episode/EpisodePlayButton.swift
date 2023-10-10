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
    
    var body: some View {
        Button {
            episode.startPlayback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                if let progress = progress {
                    if progress.progress >= 1 {
                        Text("100%")
                            .font(.caption.smallCaps())
                            .bold()
                    } else {
                        Text((progress.duration - progress.currentTime).numericTimeLeft())
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
    func fetchProgress() {
        Task.detached {
            progress = await OfflineManager.shared.getProgress(item: episode)
        }
    }
}

#Preview {
    EpisodePlayButton(episode: Episode.fixture)
}
