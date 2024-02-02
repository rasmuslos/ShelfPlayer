//
//  PlaybackSpeedSelector.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

struct PlaybackSpeedButton: View {
    let playbackRates: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]
    
    var body: some View {
        Menu {
            ForEach(playbackRates, id: \.hashValue) { rate in
                Button {
                    AudioPlayer.shared.playbackRate = rate
                } label: {
                    Text(verbatim: "\(rate)x")
                }
            }
        } label: {
            if AudioPlayer.shared.playbackRate == 1 {
                Text(verbatim: "1x")
            } else if AudioPlayer.shared.playbackRate == 2 {
                Text(verbatim: "2x")
            } else {
                Text(String(AudioPlayer.shared.playbackRate)) + Text(verbatim: "x")
            }
        } primaryAction: {
            var rate = AudioPlayer.shared.playbackRate + 0.25
            
            if rate > 2 {
                rate = 0.25
            }
            
            AudioPlayer.shared.playbackRate = rate
        }
        .fontDesign(.rounded)
        .buttonStyle(.plain)
    }
}
