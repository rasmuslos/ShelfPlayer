//
//  PlaybackSpeedSelector.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI

struct PlaybackSpeedSelector: View {
    @State var currentSpeed = AudioPlayer.shared.getPlaybackRate()
    
    var body: some View {
        Menu {
            Button("0.25x") {
                setPlaybackSpeed(0.25)
            }
            Button("0.5x") {
                setPlaybackSpeed(0.5)
            }
            Button("0.75x") {
                setPlaybackSpeed(0.75)
            }
            Button("1x") {
                setPlaybackSpeed(1)
            }
            Button("1.25x") {
                setPlaybackSpeed(1.25)
            }
            Button("1.5x") {
                setPlaybackSpeed(1.5)
            }
            Button("1.75x") {
                setPlaybackSpeed(1.75)
            }
            Button("2x") {
                setPlaybackSpeed(2)
            }
        } label: {
            if currentSpeed == 1 {
                Text("1x")
            } else if currentSpeed == 2 {
                Text("2x")
            } else {
                Text(String(currentSpeed)) + Text("x")
            }
        } primaryAction: {
            var speed = currentSpeed + 0.25
            
            if speed > 2 {
                speed = 0.25
            }
            
            setPlaybackSpeed(speed)
        }
        .fontDesign(.rounded)
        .buttonStyle(.plain)
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playbackRateChanged), perform: { _ in
            currentSpeed = AudioPlayer.shared.getPlaybackRate()
        })
    }
}

// MARK: Helper

extension PlaybackSpeedSelector {
    func setPlaybackSpeed(_ speed: Float) {
        AudioPlayer.shared.setPlaybackRate(speed)
    }
}
