//
//  PodcastsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

internal struct PodcastList: View {
    let podcasts: [Podcast]
    
    var body: some View {
        ForEach(podcasts) { podcast in
            PodcastRow(podcast: podcast)
        }
    }
}


private struct PodcastRow: View {
    let podcast: Podcast
    
    var body: some View {
        NavigationLink(destination: PodcastView(podcast)) {
            HStack(spacing: 0) {
                ItemImage(cover: podcast.cover)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(podcast.name)
                        .lineLimit(1)
                    
                    if let author = podcast.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 12)
            }
            .contentShape(.hoverMenuInteraction, Rectangle())
        }
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        List {
            PodcastList(podcasts: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
}
#endif
