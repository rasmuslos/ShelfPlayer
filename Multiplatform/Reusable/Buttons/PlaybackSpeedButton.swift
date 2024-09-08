//
//  PlaybackSpeedSelector.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

internal struct PlaybackSpeedButton: View {
    @Default(.playbackSpeedAdjustment) private var playbackSpeedAdjustment
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let playbackRates: [Percentage] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
    
    var body: some View {
        Menu {
            Options(selected: .init(get: { viewModel.playbackRate }, set: { AudioPlayer.shared.playbackRate = $0 }))
        } label: {
            Text(format(viewModel.playbackRate))
                .fixedSize()
                .contentTransition(.numericText())
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

internal extension PlaybackSpeedButton {
    struct Options: View {
        @Default(.customPlaybackSpeed) private var customPlaybackSpeed
        
        @Binding var selected: Percentage
        let playbackRates: [Percentage] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
        
        var body: some View {
            ForEach(playbackRates, id: \.hashValue) { rate in
                Toggle(format(rate), isOn: .init(get: { selected == rate }, set: {
                    if $0 {
                        selected = rate
                    }
                }))
                .tag(rate)
            }
            
            if customPlaybackSpeed != 1.0 {
                Divider()
                
                Toggle(format(customPlaybackSpeed), isOn: .init(get: { selected == customPlaybackSpeed }, set: {
                    if $0 {
                        selected = customPlaybackSpeed
                    }
                }))
                .tag(customPlaybackSpeed)
            }
        }
    }
}

private func format(_ percentage: Percentage) -> String {
    if percentage == 1 {
        return "1x"
    } else if percentage == 2 {
        return "2x"
    } else {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let text = formatter.string(from: NSNumber(value: percentage)) ?? "?"
        return "\(text)x"
    }
}
