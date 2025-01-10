//
//  SwipeActionsModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

internal struct SwipeActionsModifier: ViewModifier {
    @Default(.tintColor) private var tintColor
    
    let item: PlayableItem
    
    @Binding var loading: Bool
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                QueueButton(item: item, hideLast: true)
                    .tint(tintColor.accent)
                    .labelStyle(.iconOnly)
            }
            .swipeActions(edge: .leading) {
                Button {
                    Task {
                        loading = true
                        try await AudioPlayer.shared.play(item)
                        loading = false
                    }
                } label: {
                    Label("play", systemImage: "play")
                }
                .tint(tintColor.color)
                .labelStyle(.iconOnly)
            }
            .swipeActions(edge: .trailing) {
                DownloadButton(item: item, tint: true)
                    .labelStyle(.iconOnly)
            }
            .swipeActions(edge: .trailing) {
                ProgressButton(item: item, tint: true)
                    .labelStyle(.iconOnly)
            }
    }
}

#if DEBUG
#Preview {
    List {
        AudiobookList(sections: .init(repeating: [.audiobook(audiobook: .fixture)], count: 7))
    }
}
#endif
