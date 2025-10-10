//
//  WidgetItemButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import SwiftUI
import AppIntents
import ShelfPlayerKit

struct WidgetItemButton: View {
    let item: PlayableItem?
    let isPlaying: Bool?
    
    let entity: ItemEntity?
    
    private var intent: (any AppIntent)? {
        if let isPlaying {
            if isPlaying {
                PauseIntent()
            } else {
                PlayIntent()
            }
        } else if let entity {
            StartIntent(item: entity)
        } else {
            nil
        }
    }
    private var label: LocalizedStringKey? {
        if let isPlaying {
            if isPlaying {
                "pause"
            } else {
                "play"
            }
        } else if entity != nil {
            "start"
        } else {
            "play"
        }
    }
    private var systemImage: String? {
        if isPlaying == true {
            "pause.fill"
        } else {
            "play.fill"
        }
    }
    
    var body: some View {
        Group {
            if let intent, let label, let systemImage {
                Button(intent: intent) {
                    ZStack {
                        Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                            .hidden()
                        
                        Label(label, systemImage: systemImage)
                    }
                }
            } else {
                Label("play", systemImage: "play.fill")
            }
        }
    }
}
