//
//  PlaybackControls.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackControls: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(SkipController.self) private var skipController

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
        if UIDevice.current.userInterfaceIdiom == .pad {
            2.8
        } else {
            2
        }
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
                    Text(chapter.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                        .contentTransition(.numericText())
                        .animation(.smooth, value: remaining)
                }
            } complete: {
                satellite.seek(to: satellite.chapterDuration * $0, insideChapter: true) {
                    Task { @MainActor in
                        viewModel.seeking = nil
                    }
                }
            }

            Spacer(minLength: 8)

            LazyVGrid(columns: [.init(alignment: .trailing), .init(alignment: .center), .init(alignment: .leading)]) {
                backwardButton
                    .font(.title)

                PlaybackTogglePlayButton()
                    .font(.largeTitle)

                forwardButton
                    .font(.title)
            }
            Spacer(minLength: 8)

            BottomSlider()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .compositingGroup()
        .drawingGroup()
    }
}

private struct BottomSlider: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

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
                Text(remaining, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                    .contentTransition(.numericText())
                    .transition(.opacity)
                    .animation(.smooth, value: remaining)
            } complete: {
                satellite.seek(to: satellite.duration * $0, insideChapter: false) {
                    Task { @MainActor in
                        viewModel.seekingTotal = nil
                    }
                }
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
