//
//  AudiobookRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 15.02.25.
//

import SwiftUI
import ShelfPlayback

struct AudiobookRow: View {
    let title: String
    let small: Bool
    let audiobooks: [Audiobook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if audiobooks.count > 5 {
                    NavigationLink(destination: RowGridView(title: title, audiobooks: audiobooks)) {
                        HStack(spacing: 8) {
                            RowTitle(title: title, fontDesign: .serif)
                            
                            Image(systemName: "chevron.right")
                                .symbolVariant(.circle.fill)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(.isLink)
                    .accessibilityLabel(Text(title))
                } else {
                    RowTitle(title: title, fontDesign: .serif)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
            
            AudiobookHGrid(audiobooks: audiobooks, small: small)
        }
    }
}

private struct RowGridView: View {
    let title: String
    let audiobooks: [Audiobook]
    
    private var sections: [AudiobookSection] {
        audiobooks.map { .audiobook(audiobook: $0)}
    }
    
    var body: some View {
        ScrollView {
            AudiobookVGrid(sections: sections) { _ in }
                .padding(.horizontal, 20)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(PlaybackSafeAreaPaddingModifier())
    }
}

#if DEBUG
#Preview {
    ScrollView {
        AudiobookRow(title: "Title", small: true, audiobooks: .init(repeating: .fixture, count: 7))
    }
}
#endif
