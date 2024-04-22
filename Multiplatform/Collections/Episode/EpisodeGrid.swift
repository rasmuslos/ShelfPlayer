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
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    var body: some View {
        let width = UIScreen.main.bounds.width - padding * 2
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())].repeated(count: amount), spacing: 0) {
                ForEach(episodes) { episode in
                    NavigationLink(destination: EpisodeView(episode: episode)) {
                        EpisodeList.EpisodeRow(episode: episode)
                            .padding(.leading, gap)
                            .frame(width: width)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.leading, gap)
            .padding(.trailing, padding)
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
