//
//  PlaybackSpeedSelector.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import AudiobooksKit

struct PlaybackSpeedSelector: View {
    @State var currentSpeed = AudioPlayer.shared.getPlaybackRate()
    
    var body: some View {
        Menu {
            Button {
                setPlaybackSpeed(0.25)
            } label: {
                Text(verbatim: "0.25x")
            }
            Button {
                setPlaybackSpeed(0.5)
            } label: {
                Text(verbatim: "0.5x")
            }
            Button {
                setPlaybackSpeed(0.75)
            } label: {
                Text(verbatim: "0.75x")
            }
            Button {
                setPlaybackSpeed(1)
            } label: {
                Text(verbatim: "1x")
            }
            Button {
                setPlaybackSpeed(1.25)
            } label: {
                Text(verbatim: "1.25x")
            }
            Button {
                setPlaybackSpeed(1.5)
            } label: {
                Text(verbatim: "1.5x")
            }
            Button {
                setPlaybackSpeed(1.75)
            } label: {
                Text(verbatim: "1.25x")
            }
            Button {
                setPlaybackSpeed(2)
            } label: {
                Text(verbatim: "2x")
            }
        } label: {
            if currentSpeed == 1 {
                Text(verbatim: "1x")
            } else if currentSpeed == 2 {
                Text(verbatim: "2x")
            } else {
                Text(String(currentSpeed)) + Text(verbatim: "x")
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
