//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPPlayback

struct PlayButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let item: PlayableItem
    
    @State private var entity: ItemProgress? = nil
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
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
            ZStack {
                Label(String("FFS"), systemImage: "waveform")
                    .opacity(0)
                
                if let entity = entity {
                    if entity.progress > 0 && entity.progress < 1 {
                        Label {
                            Text(label)
                            + Text(verbatim: " • ")
                            + Text(String((entity.duration - entity.currentTime).timeLeft()))
                        } icon: {
                            Label("playing", systemImage: labelImage)
                                .labelStyle(.iconOnly)
                                .frame(width: 25)
                                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                                .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                        }
                    } else {
                        Label(label, systemImage: labelImage)
                    }
                } else {
                    ProgressIndicator()
                }
            }
            .font(.headline)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
        }
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
                        .foregroundStyle(Color.gray.opacity(0.4))
                        .frame(width: geometry.size.width * (entity?.progress ?? 0))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .modifier(ButtonHoverEffectModifier(cornerRadius: 7, hoverEffect: .lift))
        .onAppear {
            // If this is inside `init` the app will hang
            entity = OfflineManager.shared.requireProgressEntity(item: item)
        }
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
