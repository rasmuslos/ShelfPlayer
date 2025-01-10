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
        NavigationLink(destination: EpisodeView(episode, zoomID: nil)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(episode.name)
                    .lineLimit(2)
                    .bold()
                    .font(.callout)
                
                if let description = episode.descriptionText {
                    Text(description)
                        .lineLimit(3)
                        .font(.footnote)
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
                    
                    // DownloadIndicator(item: episode)
                        // .font(.caption)
                }
                .padding(.top, 12)
            }
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .buttonStyle(.plain)
        .modifier(EpisodeContextMenuModifier(episode: episode))
        .modifier(SwipeActionsModifier(item: episode, loading: $loading))
        .listRowInsets(.init(top: 12, leading: 20, bottom: 12, trailing: 20))
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
}
#endif
