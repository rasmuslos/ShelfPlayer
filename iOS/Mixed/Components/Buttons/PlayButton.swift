//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct PlayButton: View {
    let item: PlayableItem
    let entity: OfflineProgress
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
        entity = OfflineManager.shared.requireProgressEntity(item: item)
    }
    
    private var labelImage: String {
        if item == AudioPlayer.shared.item {
            return AudioPlayer.shared.playing ? "waveform" : "pause.fill"
        } else {
            return "play.fill"
        }
    }
    
    var body: some View {
        let label = item as? Audiobook != nil ? String(localized: "listen") : String(localized: "play")
        
        Button {
            item.startPlayback()
        } label: {
            if entity.progress > 0 && entity.progress < 1 {
                Label {
                    Text(label)
                    + Text(verbatim: " • ")
                    + Text(String((entity.duration - entity.currentTime).timeLeft()))
                } icon: {
                    Image(systemName: labelImage)
                        .contentTransition(.symbolEffect(.replace))
                }
            } else {
                Label(label, systemImage: labelImage)
            }
        }
        .buttonStyle(PlayNowButtonStyle(percentage: entity.progress))
        .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
