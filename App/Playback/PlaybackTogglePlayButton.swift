//
//  PlaybackTogglePlayButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackTogglePlayButton: View {
    @Environment(Satellite.self) private var satellite

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Button(satellite.isPlaying ? "playback.pause" : "playback.play", systemImage: satellite.isPlaying ? "pause" : "play") {
            satellite.togglePlaying()
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .imageScale(.large)
        .symbolVariant(.fill)
        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
        .opacity(isLoading ? 0 : 1)
        .overlay {
            if isLoading {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, isActive: isLoading)
            }
        }
        .accessibilityRemoveTraits(.isImage)
        .id(satellite.nowPlayingItemID)
    }
}

struct PlaybackSmallTogglePlayButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        ZStack {
            Group {
                Image(systemName: "play.fill")
                Image(systemName: "pause.fill")
            }
            .hidden()

            Group {
                if let currentItemID = satellite.nowPlayingItemID, satellite.isLoading(observing: currentItemID) {
                    ProgressView()
                } else if satellite.isBuffering || satellite.nowPlayingItemID == nil {
                    ProgressView()
                } else {
                    Button {
                        satellite.togglePlaying()
                    } label: {
                        Label(satellite.isPlaying ? "playback.pause" : "playback.play", systemImage: satellite.isPlaying ? "pause.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            .animation(.spring(duration: 0.2, bounce: 0.7), value: satellite.isPlaying)
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.blurReplace)
        }
    }
}
