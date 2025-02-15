//
//  AudiobookRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 15.02.25.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookRow: View {
    let title: String
    let small: Bool
    let audiobooks: [Audiobook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if audiobooks.count > 5 {
                    NavigationLink {
                        ScrollView {
                            AudiobookVGrid(sections: audiobooks.map { .audiobook(audiobook: $0)}) { _ in }
                                .padding(.horizontal, 20)
                        }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        // .modifier(NowPlaying.SafeAreaModifier())
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            RowTitle(title: title, fontDesign: .serif)
                            
                            Image(systemName: "chevron.right")
                                .symbolVariant(.circle.fill)
                                .imageScale(.small)
                        }
                    }
                    .buttonStyle(.plain)
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

#if DEBUG
#Preview {
    AudiobookRow(title: "Title", small: true, audiobooks: .init(repeating: .fixture, count: 7))
}
#endif
