//
//  PlaybackSkipButtons.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackBackwardButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    @State private var seekTimer: Timer?

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Label("playback.skip.backward", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
            .labelStyle(.iconOnly)
            .foregroundStyle(isLoading ? .secondary : .primary)
            .padding(12)
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.5, perform: {}, onPressingChanged: { pressing in
                if pressing {
                    skipController.skipPressed(forwards: false, satellite: satellite)
                    seekTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { [satellite, skipController] _ in
                        Task { @MainActor in
                            skipController.skipPressed(forwards: false, satellite: satellite)
                        }
                    }
                } else {
                    seekTimer?.invalidate()
                    seekTimer = nil
                }
            })
            .padding(-12)
            .disabled(isLoading)
            .symbolEffect(.rotate.counterClockwise.byLayer, options: .speed(10), value: skipController.notifySkipBackwards)
            .animation(.smooth, value: isLoading)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Text(verbatim: "\(viewModel.skipBackwardsInterval)"))
    }
}

struct PlaybackForwardButton: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    @State private var seekTimer: Timer?

    private var isLoading: Bool {
        if let currentItemID = satellite.nowPlayingItemID {
            satellite.isBuffering || satellite.isLoading(observing: currentItemID)
        } else {
            true
        }
    }

    var body: some View {
        Label("playback.skip.forward", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
            .labelStyle(.iconOnly)
            .foregroundStyle(isLoading ? .secondary : .primary)
            .padding(12)
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.5, perform: {}, onPressingChanged: { pressing in
                if pressing {
                    skipController.skipPressed(forwards: true, satellite: satellite)
                    seekTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { [satellite, skipController] _ in
                        Task { @MainActor in
                            skipController.skipPressed(forwards: true, satellite: satellite)
                        }
                    }
                } else {
                    seekTimer?.invalidate()
                    seekTimer = nil
                }
            })
            .padding(-12)
            .disabled(isLoading)
            .symbolEffect(.rotate.clockwise.byLayer, options: .speed(10), value: skipController.notifySkipForwards)
            .animation(.smooth, value: isLoading)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Text(verbatim: "\(viewModel.skipForwardsInterval)"))
    }
}
