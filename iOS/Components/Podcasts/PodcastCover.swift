//
//  PodcastCover.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct PodcastCover: View {
    let podcast: Podcast
    
    var body: some View {
        VStack(alignment: .leading) {
            ItemImage(image: podcast.image)
            
            Text(podcast.name)
                .lineLimit(1)
            if let author = podcast.author {
                Text(author)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PodcastCover(podcast: Podcast.fixture)
}
