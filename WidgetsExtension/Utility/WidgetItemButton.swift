//
//  WidgetItemButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import SwiftUI
import ShelfPlayerKit

struct WidgetItemButton: View {
    let item: PlayableItem?
    let isPlaying: Bool?
    
    let entity: ItemEntity?
    
    var body: some View {
        if let isPlaying {
            if isPlaying {
                Button("pause", systemImage: "pause.fill", intent: PauseIntent())
            } else {
                Button("play", systemImage: "play.fill", intent: PlayIntent())
            }
        } else if let entity {
            Button("start", systemImage: "play.fill", intent: StartIntent(item: entity))
        } else {
            Button("play", systemImage: "play.fill") {}
                .disabled(true)
        }
    }
}
