//
//  EpisodeRow.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPBase

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

#Preview {
    EpisodeRow(episode: .fixture)
}
