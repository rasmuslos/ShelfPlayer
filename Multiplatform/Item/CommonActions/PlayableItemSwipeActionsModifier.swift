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

struct PlayableItemSwipeActionsModifier: ViewModifier {
    @Environment(Satellite.self) private var satellite
    @Default(.tintColor) private var tintColor
    
    let itemID: ItemIdentifier
    
    @State private var download: DownloadStatusTracker
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        _download = .init(initialValue: .init(itemID: itemID))
    }
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                QueueButton(itemID: itemID, hideLast: true)
                    .labelStyle(.iconOnly)
                    .tint(tintColor.accent)
            }
            .swipeActions(edge: .leading) {
                Button("item.play", systemImage: "play") {
                    satellite.start(itemID)
                }
                .labelStyle(.iconOnly)
                .disabled(satellite.isLoading(observing: itemID))
                .tint(tintColor.color)
            }
            .swipeActions(edge: .trailing) {
                DownloadButton(itemID: itemID, tint: true, initialStatus: download.status)
                    .labelStyle(.iconOnly)
            }
            .swipeActions(edge: .trailing) {
                ProgressButton(itemID: itemID, tint: true)
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
