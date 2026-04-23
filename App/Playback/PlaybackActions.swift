//
//  PlaybackActions.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel

    @ViewBuilder
    private var queueButton: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.isRatePickerVisible = false
                viewModel.isQueueVisible.toggle()
            }
        } label: {
            Label("playback.queue", systemImage: "list.number")
                .padding(12)
                .contentShape(.rect)
        }
        .modify(if: viewModel.isQueueVisible) {
            $0.glassEffect(.clear.interactive(), in: .circle)
        }
        .padding(-12)
    }

    var body: some View {
        LazyVGrid(columns: .init(repeating: .init(alignment: .centerFirstTextBaseline), count: 4)) {
            PlaybackRateButton()
            PlaybackSleepTimerButton()
            PlaybackAirPlayButton()
            queueButton
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .font(.headline)
        .fontWeight(.bold)
        .fontDesign(.rounded)
        .geometryGroup()
        .compositingGroup()
    }
}

#if DEBUG
#Preview {
    PlaybackActions()
        .previewEnvironment()
}
#endif
