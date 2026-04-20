//
//  EpisodePlayButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct EpisodePlayButton: View {
    @Environment(\.displayContext) private var displayContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(Satellite.self) private var satellite

    let episode: Episode
    let highlighted: Bool

    @State private var tracker: ProgressTracker

    init(episode: Episode, highlighted: Bool = false) {
        self.episode = episode
        self.highlighted = highlighted

        _tracker = .init(initialValue: .init(itemID: episode.id))
    }

    private var isPlaying: Bool {
        satellite.nowPlayingItem == episode
    }
    private var isLoading: Bool {
        satellite.isLoading(observing: episode.id)
    }

    private var label: String {
        func formatDuration() -> String {
            episode.duration.formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute], maximumUnitCount: 1))
                .lowercased()
        }

        if let isFinished = tracker.isFinished, isFinished {
            return String(localized: "item.play.again")
        } else if let progress, progress <= 0 {
            return formatDuration()
        } else if isPlaying, satellite.duration > 0 {
            return (satellite.duration - satellite.currentTime)
                .formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                .lowercased()
        } else if let currentTime = tracker.currentTime, let progress, progress > 0 {
            return ((self.tracker.duration ?? episode.duration) - currentTime)
                .formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1))
                .lowercased()
        } else {
            return formatDuration()
        }
    }
    private var icon: String {
        if isPlaying && satellite.isPlaying {
            return "pause.fill"
        }

        return "play.fill"
    }

    private var progress: Percentage? {
        if isPlaying, satellite.duration > 0 {
            return satellite.currentTime / satellite.duration
        } else {
            return tracker.progress
        }
    }
    private var progressVisible: Bool {
        if isPlaying {
            return true
        }

        if let progress {
            return progress > 0 && progress < 1
        }

        return false
    }

    @ViewBuilder
    private func text() -> some View {
        HStack(spacing: 0) {
            ZStack {
                Image(systemName: "play.fill")
                    .hidden()

                Image(systemName: icon)
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    .opacity(isLoading ? 0 : 1)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .controlSize(.small)
            .padding(.trailing, 4)

            Rectangle()
                .fill(.gray.opacity(0.44))
                .overlay(alignment: .leading) {
                    if let progress {
                        Rectangle()
                            .frame(width: progressVisible ? 40 * progress : 0)
                    }
                }
                .frame(width: progressVisible ? 40 : 0, height: 5)
                .clipShape(.rect(cornerRadius: .infinity))
                .padding(.leading, progressVisible ? 4 : 0)
                .padding(.trailing, progressVisible ? 8 : 0)
                .animation(.smooth, value: progress)
                .animation(.smooth, value: progressVisible)

            Text(label)
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))
        }
        .bold()
        .font(.caption)
    }

    var body: some View {
        Button {
            satellite.start(episode.id, origin: displayContext.origin)
        } label: {
            text()
                .opacity(highlighted ? 0 : 1)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(highlighted ? .white : .secondary.opacity(0.2))
                .foregroundStyle(highlighted ? .black : .accentColor)
                .modify(if: highlighted) {
                    $0
                        .reverseMask {
                            text()
                        }
                }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .clipShape(.rect(cornerRadius: .infinity))
        .hoverEffect(.highlight)
    }
}
