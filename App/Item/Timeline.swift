//
//  Timeline.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct Timeline: View {
    @Environment(Satellite.self) private var satellite

    let sessionLoader: SessionLoader
    var item: PlayableItem? = nil

    private var isPlaying: Bool {
        satellite.nowPlayingItemID == item?.id
    }

    private func rowText(session: SessionPayload) -> LocalizedStringKey {
        if session.startDate.distance(to: .now) > 60 * 60 * 24 {
            "item.timeline.row \(session.timeListening?.formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.day, .hour, .minute, .second], maximumUnitCount: 1)) ?? "?") \(session.startDate.formatted(date: .abbreviated, time: .shortened))"
        } else {
            "item.timeline.row \(session.timeListening?.formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.day, .hour, .minute, .second], maximumUnitCount: 1)) ?? "?") \(session.startDate.formatted(.relative(presentation: .named)))"
        }
    }

    @ViewBuilder
    private func capsule<Content: View>(title: LocalizedStringKey, isLoading: Bool, @ViewBuilder text: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 0) {
                text()
                    .bold()
                    .font(.title3)

                Spacer(minLength: 0)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.background.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func row(text: Text, color: Color, systemImage: String) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 26)

                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(color.isLight == true ? .black : .white)
            }
            .padding(.trailing, 8)
            .accessibilityHidden(true)

            text
                .font(.caption)

            Spacer()
        }
    }

    private var releasedString: String? {
        (item as? Audiobook)?.released
    }

    private var hasTimelineContent: Bool {
        !sessionLoader.sessions.isEmpty || isPlaying || releasedString != nil
    }

    @ViewBuilder
    private var capsules: some View {
        HStack(spacing: 12) {
            capsule(title: "item.timeline.total",
                    isLoading: sessionLoader.isLoading) {
                Text(sessionLoader.totalTimeSpendListening, format: .duration(unitsStyle: .full, allowedUnits: [.day, .hour, .minute], maximumUnitCount: 1))
            }

            capsule(title: "item.lastPlayed", isLoading: sessionLoader.mostRecent == nil && sessionLoader.isLoading) {
                if !isPlaying, let mostRecent = sessionLoader.mostRecent {
                    Text(mostRecent.startDate, style: .relative)
                } else {
                    Text("loading")
                        .redacted(reason: .placeholder)
                }
            }
        }
    }

    @ViewBuilder
    private var sessionsTimeline: some View {
        LazyVStack(spacing: 20) {
            if isPlaying {
                row(text: Text("item.timeline.playing"), color: .blue, systemImage: "pause.fill")
            }

            ForEach(sessionLoader.sessions) {
                row(text: Text(rowText(session: $0)), color: .accentColor, systemImage: "play.fill")
            }

            if let released = releasedString {
                row(text: Text(verbatim: "item.released \(released)"), color: .green, systemImage: "plus")
            }
        }
        .background(alignment: .leading) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 2, height: nil)
                .padding(.leading, 12)
        }
    }

    @ViewBuilder
    private var loadingState: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
            .accessibilityLabel("loading")
    }

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView("item.timeline.empty",
                               systemImage: "clock.arrow.circlepath",
                               description: Text("item.timeline.empty.description"))
    }

    @ViewBuilder
    private var emptyHint: some View {
        Text("item.timeline.empty.hint")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    @ViewBuilder
    private var timelineContent: some View {
        VStack(spacing: 12) {
            if !sessionLoader.sessions.isEmpty || sessionLoader.isLoading {
                capsules
            }
            sessionsTimeline
            if sessionLoader.sessions.isEmpty && sessionLoader.isFinished {
                emptyHint
            }
        }
    }

    var body: some View {
        Group {
            if hasTimelineContent {
                ScrollView {
                    timelineContent
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
            } else if sessionLoader.isLoading || !sessionLoader.isFinished {
                loadingState
            } else {
                emptyState
            }
        }
        .onReceive(AudioPlayer.shared.events.playbackItemChanged) { _ in
            sessionLoader.refresh()
        }
        .onAppear {
            sessionLoader.refresh()
        }
    }
}

#if DEBUG
private extension Audiobook {
    static func previewPlaying(released: String?) -> Audiobook {
        Audiobook(id: .fixture,
                  name: "Now Playing Sample",
                  authors: ["Preview"],
                  description: nil,
                  genres: [],
                  addedAt: Date(),
                  released: released,
                  size: nil,
                  duration: 60 * 60,
                  subtitle: nil,
                  narrators: [],
                  series: [],
                  explicit: false,
                  abridged: false)
    }
}

private struct TimelinePreviewWrapper: View {
    let title: String
    let sessionLoader: SessionLoader
    var item: PlayableItem? = nil

    var body: some View {
        NavigationStack {
            Timeline(sessionLoader: sessionLoader, item: item)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
        .previewEnvironment()
    }
}

#Preview("Loading") {
    TimelinePreviewWrapper(title: "Loading",
                           sessionLoader: .preview(.loading),
                           item: Audiobook.fixture)
}

#Preview("Empty") {
    TimelinePreviewWrapper(title: "Empty",
                           sessionLoader: .preview(.empty),
                           item: nil)
}

#Preview("Empty + released") {
    TimelinePreviewWrapper(title: "Empty + released",
                           sessionLoader: .preview(.empty),
                           item: Audiobook.fixture)
}

#Preview("Empty + playing") {
    TimelinePreviewWrapper(title: "Empty + playing",
                           sessionLoader: .preview(.empty),
                           item: Audiobook.previewPlaying(released: nil))
}

#Preview("Empty + playing + released") {
    TimelinePreviewWrapper(title: "Empty + playing + released",
                           sessionLoader: .preview(.empty),
                           item: Audiobook.previewPlaying(released: "1949"))
}

#Preview("Populated") {
    TimelinePreviewWrapper(title: "Populated",
                           sessionLoader: .preview(.populated),
                           item: Audiobook.fixture)
}

#Preview("Populated + playing") {
    TimelinePreviewWrapper(title: "Populated + playing",
                           sessionLoader: .preview(.populated),
                           item: Audiobook.previewPlaying(released: "1949"))
}
#endif
