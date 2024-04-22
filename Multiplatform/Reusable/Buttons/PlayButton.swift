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
    let entity: ItemProgress
    
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
                        .frame(width: 25)
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                        .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                }
            } else {
                Label(label, systemImage: labelImage)
            }
        }
        .buttonStyle(PlayNowButtonStyle(percentage: entity.progress))
    }
}

struct PlayNowButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    let percentage: Double
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .background {
                ZStack {
                    if colorScheme == .dark {
                        Color.white
                    } else {
                        Color.black
                    }
                    
                    GeometryReader { geometry in
                        Rectangle()
                            .foregroundStyle(.secondary)
                            .frame(width: geometry.size.width * percentage)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
