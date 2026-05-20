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

    var onMeshBackground: Bool = false

    @ViewBuilder
    private var queueButton: some View {
        Button {
            withAnimation(.snappy) {
                viewModel.activeCard = viewModel.activeCard == .queue ? nil : .queue
            }
        } label: {
            Label("playback.queue", systemImage: "list.number")
                .padding(12)
                .contentShape(.capsule)
        }
        .modify(if: viewModel.activeCard == .queue) {
            $0.glassEffect(onMeshBackground ? .clear.interactive() : .regular.interactive(), in: .capsule)
        }
        .padding(-12)
    }

    var body: some View {
        // Non-lazy HStack so the icons stay mounted across selection changes —
        // a lazy grid recycles them and breaks the glass / scale animations.
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            PlaybackRateButton(onMeshBackground: onMeshBackground)
                .frame(maxWidth: .infinity)
            PlaybackSleepTimerButton(onMeshBackground: onMeshBackground)
                .frame(maxWidth: .infinity)
            PlaybackAirPlayButton()
                .frame(maxWidth: .infinity)
            queueButton
                .frame(maxWidth: .infinity)
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
