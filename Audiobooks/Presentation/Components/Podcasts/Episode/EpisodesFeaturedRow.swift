//
//  EpisodeFeaturedRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeFeaturedRow: View {
    let episodes: [Episode]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(episodes.enumerated()), id: \.offset) { index, episode in
                    NavigationLink(destination: Text(episode.id)) {
                        EpisodeFeatured(episode: episode)
                            .padding(.trailing, index == episodes.count - 1 ? 20 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, 10)
            .padding(.trailing, 10)
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

#Preview {
    NavigationStack {
        EpisodeFeaturedRow(episodes: [
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
            Episode.fixture,
        ])
    }
}
