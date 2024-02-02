//
//  EpisodeSingleList.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPBase

struct EpisodeSingleList: View {
    let episodes: [Episode]
    
    var body: some View {
        ForEach(episodes) { episode in
            NavigationLink(destination: EpisodeView(episode: episode)) {
                EpisodeRow(episode: episode, lineLimit: 2)
            }
            .listRowInsets(.init(top: 5, leading: 15, bottom: 5, trailing: 15))
            .modifier(SwipeActionsModifier(item: episode))
        }
    }
}

extension EpisodeSingleList {
    struct EpisodeRow: View {
        let episode: Episode
        let lineLimit: Int
        
        var body: some View {
            VStack(alignment: .leading) {
                Group {
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Text(formattedReleaseDate)
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
                        .lineLimit(lineLimit)
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
            .modifier(EpisodeContextMenuModifier(episode: episode))
        }
    }
}

#Preview {
    EpisodeSingleList(episodes: .init(repeating: [.fixture], count: 7))
}
