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
        HStack(spacing: 6) {
            Image(systemName: "play.fill")
            if let progress = progress {
                Text((progress.duration - progress.currentTime).numericTimeLeft())
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
