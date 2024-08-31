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
    
    var body: some View {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode)) {
                    EpisodeRow(episode: episode)
                }
                .modifier(SwipeActionsModifier(item: episode))
                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
    }
}

extension EpisodeList {
    struct EpisodeRow: View {
        let episode: Episode
        
        var body: some View {
            HStack {
                ItemImage(image: episode.cover)
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
            .modifier(EpisodeContextMenuModifier(episode: episode))
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
