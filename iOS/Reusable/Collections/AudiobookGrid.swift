//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct AudiobookVGrid: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(Array(audiobooks.enumerated()), id: \.offset) { index, audiobook in
                NavigationLink {
                    AudiobookView(audiobook: audiobook)
                } label: {
                    ItemStatusImage(item: audiobook)
                        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AudiobookHGrid: View {
    let audiobooks: [Audiobook]
    var amount = 3
    
    var body: some View {
        // size = (width - (padding leading (20) + padding trailing (20) + gap (10) * (amount - 1))) / amount
        let size = (UIScreen.main.bounds.width - (40 + 10 * CGFloat(amount - 1))) / CGFloat(amount)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(audiobooks) { audiobook in
                    NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                        ItemStatusImage(item: audiobook)
                            .frame(width: size)
                            .padding(.leading, 10)
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
        ScrollView {
            AudiobookVGrid(audiobooks: [
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

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookHGrid(audiobooks: [
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

