//
//  EpisodeSingleList.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPFoundation

struct EpisodeSingleList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) { episode in
            NavigationLink(destination: EpisodeView(episode)) {
                EpisodeRow(episode: episode)
            }
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            .modifier(SwipeActionsModifier(item: episode, loading: .constant(false)))
        }
    }
}

internal extension EpisodeSingleList {
    struct EpisodeRow: View {
        let episode: Episode
        
        var body: some View {
            VStack(alignment: .leading) {
                Group {
                    if let releaseDate = episode.releaseDate {
                        Text(releaseDate, style: .date)
                    } else {
                        Text(verbatim: "")
                    }
                }
                .font(.subheadline.smallCaps())
                .foregroundStyle(.secondary)
                
                Text(episode.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = episode.descriptionText {
                    Text(description)
                        .lineLimit(2)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    EpisodePlayButton(episode: episode)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    DownloadIndicator(item: episode)
                }
            }
            .contentShape([.contextMenuPreview, .hoverEffect, .interaction], Rectangle())
            .modifier(EpisodeContextMenuModifier(episode: episode))
        }
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
