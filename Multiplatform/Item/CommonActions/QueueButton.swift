//
//  QueueButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct QueueButton: View {
    static let systemImage = "text.line.last.and.arrowtriangle.forward"
    
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    var short: Bool = false
    var hideLast: Bool = false
    
    var body: some View {
        Button(short ? "playback.queue.add.short" : "playback.queue.add", systemImage: Self.systemImage) {
            satellite.queue(itemID)
        }
        .disabled(satellite.isLoading(observing: itemID))
    }
}
