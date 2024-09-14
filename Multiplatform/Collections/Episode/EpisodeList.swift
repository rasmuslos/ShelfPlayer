//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct EpisodeList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) {
            Row(episode: $0)
        }
    }
}


private struct Row: View {
    let episode: Episode
    
    @State private var loading = false
    
    var body: some View {
        NavigationLink(destination: EpisodeView(episode)) {
            HStack(spacing: 0) {
                ItemImage(cover: episode.cover)
                    .frame(width: 92)
                    .padding(.trailing, 12)
                    .hoverEffect(.highlight)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(episode.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let description = episode.descriptionText {
                        Text(description)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .font(.caption)
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
                
                Spacer()
            }
            .contentShape(.hoverMenuInteraction, .rect())
        }
        .modifier(SwipeActionsModifier(item: episode, loading: $loading))
        .modifier(EpisodeContextMenuModifier(episode: episode))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
    .environment(NowPlaying.ViewModel())
}
#endif
