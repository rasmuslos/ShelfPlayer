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
    let color: Color
    
    @State private var error = false
    @State private var loading = false
    
    @State private var progressEntity: ItemProgress
    
    @MainActor
    init(item: PlayableItem, color: Color) {
        self.item = item
        self.color = color
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
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
        
        Menu {
            Button {
                play()
            } label: {
                Label("queue.play", systemImage: "play.fill")
            }
            
            Button {
                AudioPlayer.shared.queue(item)
            } label: {
                Label("queue.last", systemImage: "text.line.last.and.arrowtriangle.forward")
                
                if let last = AudioPlayer.shared.queue.last {
                    Text(last.name)
                }
            }
            
            ProgressButton(item: item)
        } label: {
            ZStack {
                Label(String("FFS"), systemImage: "waveform")
                    .hidden()
                
                if progressEntity.progress > 0 && progressEntity.progress < 1 {
                    Label {
                        Text(label)
                        + Text(verbatim: " • ")
                        + Text((progressEntity.duration - progressEntity.currentTime).formatted(.duration(unitsStyle: .short)))
                    } icon: {
                        if loading {
                            ProgressIndicator()
                        } else {
                            Label("playing", systemImage: labelImage)
                                .labelStyle(.iconOnly)
                                .frame(width: 25)
                                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                                .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                        }
                    }
                } else {
                    Label(label, systemImage: labelImage)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .contentShape(.rect)
        } primaryAction: {
            play()
        }
        .foregroundColor(color.isLight() ?? false ? .black : .white)
        .background {
            ZStack {
                color
                
                GeometryReader { geometry in
                    Rectangle()
                        .foregroundStyle(Color.gray.opacity(0.4))
                        .frame(width: geometry.size.width * progressEntity.progress)
                }
            }
        }
        .animation(.smooth, value: color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .modifier(ButtonHoverEffectModifier(cornerRadius: 8, hoverEffect: .lift))
    }
    
    func play() {
        if loading {
            return
        }
        
        Task {
            loading = true
            
            do {
                try await AudioPlayer.shared.play(item)
            } catch {
                self.error.toggle()
                loading = false
            }
            
            loading = false
        }
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture, color: .yellow)
}
