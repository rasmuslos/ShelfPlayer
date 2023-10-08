//
//  EpisodeTable.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeTable: View {
    let episodes: [Episode]
    var amount = 2
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(Array(episodes.enumerated()), id: \.offset) { index, episode in
                    EpisodeTableRow(episode: episode)
                        .padding(.trailing, index == episodes.count - 1 || (episodes.count % 2 == 0 && index == episodes.count - 2) ? 30 : 0)
                }
            }
            .padding(.leading, 10)
        }
    }
}

struct EpisodeTableContainer: View {
    let title: String
    let episodes: [Episode]
    let amount = 2
    
    var body: some View {
        VStack(alignment: .leading) {
            RowTitle(title: title)
            EpisodeTable(episodes: episodes, amount: amount)
        }
    }
}

#Preview {
    EpisodeTable(episodes: [
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
        Episode.fixture,
    ])
}
