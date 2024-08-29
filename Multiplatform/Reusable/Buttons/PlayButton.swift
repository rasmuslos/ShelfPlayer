//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import RFKVisuals
import ShelfPlayerKit
import SPPlayback

struct PlayButton: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let item: PlayableItem
    let color: Color?
    
    @State private var error = false
    @State private var loading = false
    
    @State private var progressEntity: ItemProgress
    
    @MainActor
    init(item: PlayableItem, color: Color?) {
        self.item = item
        self.color = color
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
    }
    
    private var background: Color {
        if let color {
            return color
        }
        
        return colorScheme == .dark ? .white : .black
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
            
            Divider()
            
            ProgressButton(item: item)
            
            if progressEntity.startedAt != nil {
                Button(role: .destructive) {
                    Task {
                        loading = true
                        
                        do {
                            try await AudiobookshelfClient.shared.deleteProgress(itemId: item.identifiers.itemID, episodeId: item.identifiers.episodeID)
                            try OfflineManager.shared.resetProgressEntity(id: progressEntity.id)
                        } catch {
                            self.error.toggle()
                        }
                        
                        loading = false
                    }
                } label: {
                    Label("progress.reset", systemImage: "xmark")
                }
            }
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
            .transition(.opacity)
            .animation(.smooth, value: progressEntity.progress)
        } primaryAction: {
            if AudioPlayer.shared.item == item {
                AudioPlayer.shared.playing.toggle()
                return
            }
            
            play()
        }
        .foregroundColor(background.isLight ? .black : .white)
        .background {
            ZStack {
                RFKVisuals.adjust(background, saturation: 0, brightness: -0.8)
                
                GeometryReader { geometry in
                    Rectangle()
                        .fill(background.isLight ? .white : .black)
                        .opacity(0.2)
                        .frame(width: geometry.size.width * progressEntity.progress)
                        .animation(.smooth, value: progressEntity.progress)
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
