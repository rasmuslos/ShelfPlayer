//
//  PodcastsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

struct PodcastList: View {
    let podcasts: [Podcast]
    
    var body: some View {
        ForEach(podcasts) { podcast in
            NavigationLink(destination: PodcastView(podcast)) {
                PodcastRow(podcast: podcast)
            }
        }
    }
}

extension PodcastList {
    struct PodcastRow: View {
        let podcast: Podcast
        
        var body: some View {
            HStack {
                ItemImage(cover: podcast.cover)
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
            .contentShape(.hoverMenuInteraction, Rectangle())
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            PodcastList(podcasts: [
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
                Podcast.fixture,
            ])
        }
    }
}
#endif
