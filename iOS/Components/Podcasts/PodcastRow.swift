//
//  PodcastRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBaseKit

struct PodcastRow: View {
    let podcast: Podcast
    
    var body: some View {
        HStack {
            ItemImage(image: podcast.image)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(podcast.name)
                    .lineLimit(1)
                
                if let author = podcast.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .modifier(PodcastContextMenuModifier(podcast: podcast))
    }
}

#Preview {
    List {
        PodcastRow(podcast: Podcast.fixture)
        PodcastRow(podcast: Podcast.fixture)
        PodcastRow(podcast: Podcast.fixture)
        PodcastRow(podcast: Podcast.fixture)
        PodcastRow(podcast: Podcast.fixture)
    }
    .listStyle(.plain)
}
