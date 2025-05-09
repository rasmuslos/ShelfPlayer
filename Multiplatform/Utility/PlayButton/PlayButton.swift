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
    
    @State private var tracker: ProgressTracker
    
    init(item: PlayableItem, color: Color?) {
        self.item = item
        self.color = color
        
        _tracker = .init(initialValue: .init(itemID: item.id))
    }
    
    private var background: Color {
        if let color {
            return color
        }
        
        return colorScheme == .dark ? .white : .black
    }
    
    private var isPlaying: Bool {
        satellite.nowPlayingItem == item
    }
    private var isLoading: Bool {
        satellite.isLoading(observing: item.id)
    }
    
    private var remaining: TimeInterval? {
        guard tracker.isFinished != true else {
            return nil
        }
        
        if isPlaying && satellite.duration > 0 {
            return satellite.duration - satellite.currentTime
        } else if isPlaying, satellite.duration > 0 {
            return (satellite.duration - satellite.currentTime)
        } else if let duration = tracker.duration, duration > 0, let currentTime = tracker.currentTime {
            return duration - currentTime
        } else if playButtonStyle.hideRemainingWhenUnplayed {
            return nil
        } else {
            return item.duration
        }
    }
    private var progress: Percentage? {
        if isPlaying, satellite.duration > 0 {
            return satellite.currentTime / satellite.duration
        } else {
            return tracker.progress
        }
    }
    
    private var label: LocalizedStringKey {
        if isPlaying {
            return satellite.isPlaying ? "playback.pause" : "playback.pause"
        }
        
        let isFinished = tracker.isFinished
        let progress = tracker.progress
        
        if item.id.type == .audiobook {
            if isFinished == true {
                return "item.play.again.audiobook"
            } else if let progress, progress > 0 {
                return "item.play.resume.audiobook"
            } else {
                return "item.play.audiobook"
            }
        } else {
            if isFinished == true {
                return "item.play.again"
            } else if let progress, progress > 0 {
                return "item.play.resume"
            } else {
                return "item.play"
            }
        }
    }
    
    private var icon: String {
        if isPlaying && satellite.isPlaying {
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
                    if isLoading {
                        ProgressView()
                            .frame(height: 0)
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
        .animation(.smooth, value: tracker.progress)
    }
    
    @ViewBuilder
    var menuContent: some View {
        Menu {
            ControlGroup {
                QueuePlayButton(itemID: item.id)
                QueueButton(itemID: item.id, hideLast: true)
            }
            
            ProgressButton(itemID: item.id, tint: false)
            
            if let progress = tracker.progress, progress > 0 {
                ProgressResetButton(itemID: item.id)
            }
        } label: {
            playButtonStyle.makeLabel(configuration: .init(progress: progress, background: background, content: .init(content: labelContent)))
        } primaryAction: {
            satellite.start(item.id)
        }
        .disabled(isLoading)
        .foregroundColor((background.isLight ?? false) ? .black : .white)
        .animation(.smooth, value: color)
    }
    
    var body: some View {
        playButtonStyle.makeMenu(configuration: .init(progress: progress, background: background, content: .init(content: menuContent)))
            .clipShape(.rect(cornerRadius: playButtonStyle.cornerRadius))
            .modifier(ButtonHoverEffectModifier(cornerRadius: playButtonStyle.cornerRadius, hoverEffect: .lift))
    }
    
    public func playButtonSize(_ playButtonStyle: any PlayButtonStyle) -> some View {
        self
            .environment(\.playButtonStyle, .init(style: playButtonStyle))
    }
}
