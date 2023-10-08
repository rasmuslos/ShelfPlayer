//
//  EpisodeTableRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeTableRow: View {
    let episode: Episode
    
    var body: some View {
        let size = UIScreen.main.bounds.width - 40
        
        HStack {
            ItemImage(image: episode.image)
                .frame(width: 75)
            
            VStack(alignment: .leading) {
                Group {
                    if let releaseDate = episode.releaseDate {
                        Text(String(releaseDate.get(.day))) + Text(".")
                        + Text(String(releaseDate.get(.month))) + Text(".")
                        + Text(String(releaseDate.get(.year)))
                    } else {
                        Text("")
                    }
                }
                .font(.caption.smallCaps())
                .foregroundStyle(.secondary)
                
                Text(episode.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = episode.description {
                    Text(description)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding(.leading, 10)
        .frame(width: size, height: 75)
    }
}
