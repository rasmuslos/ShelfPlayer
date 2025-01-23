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
    let item: PlayableItem
    var hideLast: Bool = false
    
    var body: some View {
        Button {
            AudioPlayer.shared.queue(item)
        } label: {
            Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
            
            if !hideLast, let last = AudioPlayer.shared.queue.last {
                Text(last.name)
            }
        }
    }
}
