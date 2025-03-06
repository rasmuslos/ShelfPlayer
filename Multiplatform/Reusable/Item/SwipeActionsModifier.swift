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

struct ItemSwipeActionsModifier: ViewModifier {
    @Environment(Satellite.self) private var satellite
    @Default(.tintColor) private var tintColor
    
    let item: PlayableItem
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                QueueButton(item: item, hideLast: true)
                    .labelStyle(.iconOnly)
                    .tint(tintColor.accent)
            }
            .swipeActions(edge: .leading) {
                Button("play", systemImage: "play") {
                    satellite.start(item)
                }
                .labelStyle(.iconOnly)
                .disabled(satellite.isLoading(observing: item.id))
                .tint(tintColor.color)
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
        AudiobookList(sections: .init(repeating: .audiobook(audiobook: .fixture), count: 7)) { _ in }
    }
    .previewEnvironment()
}
#endif
