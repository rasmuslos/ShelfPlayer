//
//  EpisodeTableRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeImageRow: View {
    let episode: Episode
    
    var body: some View {
        let width = UIScreen.main.bounds.width - 30
        let height: CGFloat = 90
        
        HStack {
            ItemImage(image: episode.image)
                .frame(width: height)
            
            VStack(alignment: .leading) {
                Group {
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Text(formattedReleaseDate)
                    } else {
                        Text("")
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
                    EpisodeMenu(episode: episode)
                }
            }
            
            Spacer()
        }
        .frame(width: width, height: height)
    }
}
