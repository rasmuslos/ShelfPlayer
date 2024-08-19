//
//  PlaybackSpeedSelector.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import Defaults
import SPFoundation
import SPPlayback

struct PlaybackSpeedButton: View {
    @Default(.playbackSpeedAdjustment) private var playbackSpeedAdjustment
    
    let playbackRates: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
    
    var body: some View {
        Menu {
            Options {
                AudioPlayer.shared.playbackRate = $0
            }
        } label: {
            if AudioPlayer.shared.playbackRate == 1 {
                Text(verbatim: "1x")
            } else if AudioPlayer.shared.playbackRate == 2 {
                Text(verbatim: "2x")
            } else {
                Group {
                    Text(NSNumber(value: AudioPlayer.shared.playbackRate), formatter: {
                        let formatter = NumberFormatter()
                        formatter.decimalSeparator = "."
                        formatter.minimumFractionDigits = 0
                        formatter.maximumFractionDigits = 2
                        
                        return formatter
                    }())
                    + Text(verbatim: "x")
                }
                .fixedSize()
                .contentTransition(.identity)
            }
        } primaryAction: {
            var rate = AudioPlayer.shared.playbackRate + playbackSpeedAdjustment
            
            if rate > 2 {
                rate = 0.25
            }
            
            AudioPlayer.shared.playbackRate = rate
        }
        .fontDesign(.rounded)
        .buttonStyle(.plain)
    }
}

extension PlaybackSpeedButton {
    struct Options: View {
        @Default(.customPlaybackSpeed) private var customPlaybackSpeed
        
        let callback: (Float) -> Void
        let playbackRates: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        
        var body: some View {
            ForEach(playbackRates, id: \.hashValue) { rate in
                Button {
                    callback(rate)
                } label: {
                    Text(verbatim: "\(rate)x")
                }
                .tag(rate)
            }
            
            if customPlaybackSpeed != 1.0 {
                Divider()
                
                Button {
                    callback(customPlaybackSpeed)
                } label: {
                    Text(verbatim: "\(customPlaybackSpeed)x")
                }
                .tag(customPlaybackSpeed)
            }
        }
    }
}
