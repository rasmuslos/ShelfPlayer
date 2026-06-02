//
//  PlaybackControls.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackControls: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.playbackMarqueeController) private var marqueeController
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

    @State private var displayedRemaining: TimeInterval?
    @State private var hasSettled = false

    private var currentTime: TimeInterval {
        if let seeking = viewModel.seeking {
            satellite.chapterDuration * seeking
        } else {
            satellite.currentChapterTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seeking != nil {
            satellite.chapterDuration - currentTime
        } else {
            satellite.chapterDuration
        }
    }

    private var remaining: TimeInterval {
        if viewModel.seeking != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.chapterDuration - satellite.currentChapterTime) * (1 / satellite.playbackRate)
        }
    }

    private var aspectRatio: CGFloat {
        horizontalSizeClass == .regular ? 2.8 : 2
    }

    @ViewBuilder
    private func skipText(forwards: Bool) -> some View {
        if let skipCache = skipController.skipCache {
            if (Double(-viewModel.skipBackwardsInterval) > skipCache && !forwards) || (Double(viewModel.skipForwardsInterval) < skipCache && forwards) {
                Text(abs(skipCache) ,format: .duration(unitsStyle: .positional, allowedUnits: [.second, .minute], maximumUnitCount: 2))
                    .font(.caption2)
                    .fontDesign(.monospaced)
                    .contentTransition(.numericText(value: skipCache))
                    .foregroundStyle(.secondary)
                    .animation(.snappy, value: skipCache)
            }
        }
    }

    @ViewBuilder
    private var backwardButton: some View {
        HStack(spacing: 0) {
            skipText(forwards: false)

            Spacer(minLength: 12)

            PlaybackBackwardButton()
        }
    }
    @ViewBuilder
    private var forwardButton: some View {
        HStack(spacing: 0) {
            PlaybackForwardButton()

            Spacer(minLength: 12)

            skipText(forwards: true)
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            PlaybackSlider(percentage: satellite.played, seeking: $viewModel.seeking, currentTime: currentTime, duration: duration, textFirst: false) {
                if let chapter = satellite.chapter, viewModel.seeking == nil {
                    MarqueeText(text: chapter.title, font: .caption2, foregroundStyle: .init(.secondary), alignment: .center, controller: marqueeController)
                } else {
                    Text(displayedRemaining ?? remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                        .contentTransition(.numericText())
                }
            } complete: {
                satellite.seek(to: satellite.chapterDuration * $0, insideChapter: true) {
                    Task { @MainActor in
                        viewModel.seeking = nil
                    }
                }
            }
            .onChange(of: remaining, initial: true) { _, newValue in
                if hasSettled {
                    withAnimation(.smooth) {
                        displayedRemaining = newValue
                    }
                } else {
                    displayedRemaining = newValue
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                hasSettled = true
            }

            Spacer(minLength: 8)

            HStack(spacing: 0) {
                backwardButton
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                PlaybackTogglePlayButton()
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .center)

                forwardButton
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 8)

            BottomSlider()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .compositingGroup()
    }
}

private struct BottomSlider: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @State private var displayedRemaining: TimeInterval?
    @State private var hasSettled = false

    private var replaceVolumeWithTotalProgress: Bool { AppSettings.shared.replaceVolumeWithTotalProgress }

    private var currentTime: TimeInterval {
        if let seekingTotal = viewModel.seekingTotal {
            satellite.duration * seekingTotal
        } else {
            satellite.currentTime
        }
    }
    private var duration: TimeInterval {
        if viewModel.seekingTotal != nil {
            satellite.duration - currentTime
        } else {
            satellite.duration
        }
    }

    private var remaining: TimeInterval {
        if viewModel.seekingTotal != nil {
            duration * (1 / satellite.playbackRate)
        } else {
            (satellite.duration - satellite.currentTime) * (1 / satellite.playbackRate)
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        if replaceVolumeWithTotalProgress, satellite.chapter != nil {
            PlaybackSlider(percentage: satellite.playedTotal, seeking: $viewModel.seekingTotal, currentTime: currentTime, duration: duration, textFirst: true) {
                Text(displayedRemaining ?? remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                    .contentTransition(.numericText())
            } complete: {
                satellite.seek(to: satellite.duration * $0, insideChapter: false) {
                    Task { @MainActor in
                        viewModel.seekingTotal = nil
                    }
                }
            }
            .onChange(of: remaining, initial: true) { _, newValue in
                if hasSettled {
                    withAnimation(.smooth) {
                        displayedRemaining = newValue
                    }
                } else {
                    displayedRemaining = newValue
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(500))
                hasSettled = true
            }
        } else {
            PlaybackSlider(percentage: satellite.volume, seeking: $viewModel.volumePreview, currentTime: nil, duration: nil, textFirst: true) {
                Spacer()
            } complete: { _ in
                viewModel.volumePreview = nil
            }
            .onChange(of: viewModel.volumePreview) {
                if let volume = viewModel.volumePreview {
                    Task {
                        await AudioPlayer.shared.setVolume(volume)
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    PlaybackControls()
        .previewEnvironment()
}
#endif
