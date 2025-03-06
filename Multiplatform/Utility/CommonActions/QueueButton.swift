//
//  QueueButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct QueueButton: View {
    @Environment(Satellite.self) private var satellite
    
    let item: PlayableItem
    var hideLast: Bool = false
    
    var body: some View {
        Button("queue.add", systemImage: "text.line.last.and.arrowtriangle.forward") {
            satellite.queue(item)
        }
        .disabled(satellite.isLoading(observing: item.id))
    }
}
