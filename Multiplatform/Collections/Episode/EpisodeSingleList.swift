//
//  EpisodeSingleList.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPFoundation

internal struct EpisodeSingleList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) {
            EpisodeRow(episode: $0)
        }
    }
}

private struct EpisodeRow: View {
    let episode: Episode
    
    @State private var loading = false
    
    var body: some View {
        NavigationLink(destination: EpisodeView(episode)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(episode.name)
                    .lineLimit(2)
                    .font(.headline)
                
                if let description = episode.descriptionText {
                    Text(description)
                        .lineLimit(2)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                
                HStack(spacing: 0) {
                    EpisodePlayButton(episode: episode, loading: $loading)
                    
                    if let releaseDate = episode.releaseDate {
                        Text(releaseDate, style: .date)
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                    
                    Spacer(minLength: 12)
                    
                    DownloadIndicator(item: episode)
                }
                .padding(.top, 8)
            }
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .buttonStyle(.plain)
        .modifier(EpisodeContextMenuModifier(episode: episode))
        .modifier(SwipeActionsModifier(item: episode, loading: $loading))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EpisodeSingleList(episodes: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
    .environment(NowPlaying.ViewModel())
}
#endif
