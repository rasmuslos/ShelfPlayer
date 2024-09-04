//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPFoundation

struct EpisodeList: View {
    let episodes: [Episode]
    
    private func queue(for episode: Episode) -> [Episode] {
        guard let index = episodes.firstIndex(of: episode) else {
            return []
        }
        
        return Array(episodes[index..<episodes.endIndex])
    }
    
    var body: some View {
        ForEach(episodes) { episode in
            NavigationLink(destination: EpisodeView(episode)) {
                EpisodeRow(episode: episode, queue: queue)
            }
            .modifier(SwipeActionsModifier(item: episode, queue: queue(for: episode), loading: .constant(false)))
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    }
}

extension EpisodeList {
    struct EpisodeRow: View {
        let episode: Episode
        let queue: (Episode) -> [Episode]
        
        var body: some View {
            HStack {
                ItemImage(cover: episode.cover)
                    .frame(width: 90)
                    .hoverEffect(.highlight)
                
                VStack(alignment: .leading) {
                    Group {
                        if let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                        } else {
                            Text(verbatim: "")
                        }
                    }
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                    
                    Text(episode.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let description = episode.descriptionText {
                        Text(description)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        EpisodePlayButton(episode: episode)
                        Spacer()
                        DownloadIndicator(item: episode)
                    }
                }
                
                Spacer()
            }
            .contentShape(.hoverMenuInteraction, Rectangle())
            .modifier(EpisodeContextMenuModifier(episode: episode, queue: queue(episode)))
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: [
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
                Episode.fixture,
            ])
        }
        .listStyle(.plain)
    }
}
#endif
