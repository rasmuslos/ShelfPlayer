//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase

struct AudiobookGrid: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(Array(audiobooks.enumerated()), id: \.offset) { index, audiobook in
                NavigationLink {
                    AudiobookView(audiobook: audiobook)
                } label: {
                    AudiobookCover(audiobook: audiobook)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookGrid(audiobooks: [
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
            ])
        }
    }
}

