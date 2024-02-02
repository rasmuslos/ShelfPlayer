//
//  AudiobooksList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import SPBase

struct AudiobooksList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(Array(audiobooks.enumerated()), id: \.offset) { offset, audiobook in
            NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                AudiobookRow(audiobook: audiobook)
            }
            .modifier(SwipeActionsModifier(item: audiobook))
            .listRowSeparator(offset == 0 ? .hidden : .visible, edges: .top)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AudiobooksList(audiobooks: [
                Audiobook.fixture,
                Audiobook.fixture,
            ])
        }
        .listStyle(.plain)
    }
}
