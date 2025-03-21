//
//  QueuePlayButton.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct QueuePlayButton: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    var body: some View {
        Button("queue.play", systemImage: "play.fill") {
            satellite.start(itemID)
        }
        .disabled(satellite.isLoading(observing: itemID))
    }
}
