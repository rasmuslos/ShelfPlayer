//
//  EpisodeList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import AudiobooksKit

struct EpisodeRow: View {
    let episode: Episode
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if let formattedReleaseDate = episode.formattedReleaseDate {
                    Text(formattedReleaseDate)
                } else {
                    Text("")
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
    }
}
