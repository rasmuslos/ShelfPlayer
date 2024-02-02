//
//  EpisodeTable.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBase

struct EpisodeGrid: View {
    let episodes: [Episode]
    var amount = 2
    
    var body: some View {
        let width = UIScreen.main.bounds.width - 30
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())].repeated(count: amount), spacing: 0) {
                ForEach(episodes) { episode in
                    NavigationLink(destination: EpisodeView(episode: episode)) {
                        EpisodeRow(episode: episode)
                            .padding(.leading, 10)
                            .frame(width: width)
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

#Preview {
    NavigationStack {
        EpisodeGrid(episodes: [
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
