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
            let progress = await OfflineManager.shared.getProgress(item: episode)
            withAnimation {
                self.progress = progress
            }
        }
    }
}

#Preview {
    EpisodePlayButton(episode: Episode.fixture)
}
