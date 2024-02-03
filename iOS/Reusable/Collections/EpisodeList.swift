//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase

struct EpisodeList: View {
    let episodes: [Episode]
    
    var body: some View {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    EpisodeRow(episode: episode)
                }
                .modifier(SwipeActionsModifier(item: episode))
            }
    }
}

extension EpisodeList {
    struct EpisodeRow: View {
        let episode: Episode
        
        var body: some View {
            HStack {
                ItemImage(image: episode.image)
                    .frame(width: 90)
                
                VStack(alignment: .leading) {
                    Group {
                        if let formattedReleaseDate = episode.formattedReleaseDate {
                            Text(formattedReleaseDate)
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
                    
                    Spacer()
                    
                    HStack {
                        EpisodePlayButton(episode: episode)
                        Spacer()
                        DownloadIndicator(item: episode)
                    }
                }
                
                Spacer()
            }
            .frame(height: 90)
            .modifier(EpisodeContextMenuModifier(episode: episode))
        }
    }
}

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
