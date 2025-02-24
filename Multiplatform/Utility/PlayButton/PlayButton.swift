//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import SwiftUI
import TipKit
import ShelfPlayerKit
import SPPlayback

struct PlayButton: View {
    @Environment(\.library) private var library
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.playButtonStyle) private var playButtonStyle
    
    @Environment(Satellite.self) private var satellite
    
    let item: PlayableItem
    let color: Color?
    
    let progress: ProgressTracker
    
    init(item: PlayableItem, color: Color?) {
        self.item = item
        self.color = color
        
        progress = .init(itemID: item.id)
    }
    
    private var background: Color {
        if let color {
            return color
        }
        
        return colorScheme == .dark ? .white : .black
    }
    
    private var isItemPlaying: Bool {
        satellite.item == item
    }
    
    private var remaining: TimeInterval? {
        if isItemPlaying && satellite.duration > 0 {
            satellite.duration - satellite.currentTime
        } else if let entity = progress.entity, let duration = entity.duration, duration > 0 {
            duration - entity.currentTime
        } else if playButtonStyle.hideRemainingWhenUnplayed {
            nil
        } else {
            item.duration
        }
    }
    
    private var label: LocalizedStringKey {
        if isItemPlaying {
            return satellite.playing ? "pause" : "resume"
        }
        
        if let entity = progress.entity {
            if entity.isFinished {
                return "listen.again"
            } else if entity.progress > 0 {
                return "resume"
            }
        }
        
        if item.id.type == .audiobook {
            return "listen"
        } else {
            return "play"
        }
    }
    
    private var icon: String {
        if isItemPlaying && satellite.playing {
            "pause.fill"
        } else {
            "play.fill"
        }
    }
    
    @ViewBuilder
    var labelContent: some View {
        ZStack {
            HStack(spacing: 4) {
                Group {
                    if satellite.isLoading {
                        ProgressIndicator()
                    } else {
                        Label(label, systemImage: icon)
                            .labelStyle(.iconOnly)
                            .contentTransition(.symbolEffect(.replace.upUp.wholeSymbol))
                    }
                }
                .padding(.trailing, 8)
                
                Text(label)
                    .contentTransition(.opacity)
                
                if let remaining {
                    Text(verbatim: "•")
                    Text(remaining, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2))
                }
            }
            .animation(.smooth, value: label)
        }
        .contentShape(.rect)
        .transition(.opacity)
        .animation(.smooth, value: progress.entity?.progress)
    }
    
    @ViewBuilder
    var menuContent: some View {
        Menu {
            ControlGroup {
                QueuePlayButton(item: item)
                QueueLaterButton(item: item, hideLast: true)
            }
            
            ProgressButton(item: item, tint: false)
            
            if let entity = progress.entity, entity.progress > 0 {
                ProgressResetButton(item: item)
            }
        } label: {
            playButtonStyle.makeLabel(configuration: .init(progress: progress.entity?.progress, background: background, content: .init(content: labelContent)))
        } primaryAction: {
            satellite.play(item)
        }
        .foregroundColor((background.isLight ?? false) ? .black : .white)
        .animation(.smooth, value: color)
    }
    
    var body: some View {
        playButtonStyle.makeMenu(configuration: .init(progress: progress.entity?.progress, background: background, content: .init(content: menuContent)))
            .clipShape(.rect(cornerRadius: playButtonStyle.cornerRadius))
            .modifier(ButtonHoverEffectModifier(cornerRadius: playButtonStyle.cornerRadius, hoverEffect: .lift))
    }
    
    public func playButtonSize(_ playButtonStyle: any PlayButtonStyle) -> some View {
        self
            .environment(\.playButtonStyle, .init(style: playButtonStyle))
    }
}

#if DEBUG
#Preview {
    VStack {
        PlayButton(item: Audiobook.fixture, color: .accent)
            .playButtonSize(.medium)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.accent)
    .previewEnvironment()
}

#Preview {
    PlayButton(item: Audiobook.fixture, color: .accent)
        .playButtonSize(.large)
        .previewEnvironment()
}
#endif
