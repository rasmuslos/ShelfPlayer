//
//  QueuePlayButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayback

struct QueuePlayButton: View {
    @Environment(Satellite.self) private var satellite

    let itemID: ItemIdentifier

    var body: some View {
        Button("item.play", systemImage: "play.fill") {
            satellite.start(itemID)
        }
        .disabled(satellite.isLoading(observing: itemID))
    }
}
