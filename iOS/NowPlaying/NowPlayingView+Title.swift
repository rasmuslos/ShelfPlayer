//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

extension NowPlayingViewModifier {
    struct Title: View {
        let item: PlayableItem
        let namespace: Namespace.ID
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                                .matchedGeometryEffect(id: "releaseDate", in: namespace, properties: .frame, anchor: .top)
                        } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                        .fontDesign(item as? Audiobook != nil ? .serif : .default)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .top)
                    
                    if let author = item.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}
