//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI

extension NowPlayingSheet {
    struct Title: View {
        @Binding var item: PlayableItem
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let episode = item as? Episode, let formattedReleaseDate = episode.formattedReleaseDate {
                            Text(formattedReleaseDate)
                        } else if let audiobook = item as? Audiobook {
                            if let series = audiobook.series.audiobookSeriesName ?? audiobook.series.name {
                                Text(series)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(item.author ?? "")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}
