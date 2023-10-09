//
//  EpisodeTable.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodesTable: View {
    let episodes: [Episode]
    var amount = 2
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())].repeated(count: amount), spacing: 0) {
                ForEach(episodes) { episode in
                    NavigationLink(destination: EpisodeView(episode: episode)) {
                        EpisodeTableRow(episode: episode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, 10)
            .padding(.trailing, 20)
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

struct EpisodeTableContainer: View {
    let title: String
    let episodes: [Episode]
    let amount = 2
    
    var body: some View {
        VStack(alignment: .leading) {
            RowTitle(title: title)
            EpisodesTable(episodes: episodes, amount: amount)
        }
    }
}

#Preview {
    NavigationStack {
        EpisodesTable(episodes: [
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
}
