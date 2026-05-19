//
//  PlaybackQueue.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackQueue: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @AccessibilityFocusState private var isEpisodeDescriptionFocused: Bool

    private var tintColor: TintColor { AppSettings.shared.tintColor }
    private var isMeshActive: Bool {
        AppSettings.shared.animatedNowPlayingBackground && viewModel.nowPlayingMeshColors != nil
    }

    private enum QueueSection: Hashable, Identifiable {
        case bookmarks, description, chapters, queue, upNextQueue

        var id: String {
            switch self {
                case .bookmarks: "section_bookmarks"
                case .description: "section_description"
                case .chapters: "section_chapters"
                case .queue: "section_queue"
                case .upNextQueue: "section_upNextQueue"
            }
        }

        var label: LocalizedStringKey {
            switch self {
                case .bookmarks: "item.bookmarks"
                case .description: "item.description"
                case .chapters: "item.chapters"
                case .queue: "playback.queue"
                case .upNextQueue: "playback.nextUpQueue"
            }
        }
    }

    private var visibleSections: [QueueSection] {
        var sections: [QueueSection] = []

        if !satellite.bookmarks.isEmpty {
            sections.append(.bookmarks)
        }
        if satellite.nowPlayingItem is Episode {
            sections.append(.description)
        } else if !satellite.chapters.isEmpty {
            sections.append(.chapters)
        }
        if !satellite.queue.isEmpty {
            sections.append(.queue)
        }
        if !satellite.upNextQueue.isEmpty {
            sections.append(.upNextQueue)
        }

        return sections
    }

    private func nextSection(after section: QueueSection) -> QueueSection? {
        let sections = visibleSections
        guard sections.count > 1, let idx = sections.firstIndex(of: section) else {
            return nil
        }
        return sections[(idx + 1) % sections.count]
    }

    @ViewBuilder
    private func sectionLabel(_ section: QueueSection, subtitle: String? = nil, scrollProxy: ScrollViewProxy) -> some View {
        Menu {
            ForEach(visibleSections) { other in
                Button {
                    withAnimation {
                        scrollProxy.scrollTo(other.id, anchor: .top)
                    }
                } label: {
                    Text(other.label)
                }
            }
        } label: {
            VStack(alignment: .leading) {
                Text(section.label)

                if let subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .contentShape(.rect)
        } primaryAction: {
            if let next = nextSection(after: section) {
                withAnimation {
                    scrollProxy.scrollTo(next.id, anchor: .top)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionHeader(_ section: QueueSection, scrollProxy: ScrollViewProxy) -> some View {
        sectionLabel(section, scrollProxy: scrollProxy)
            .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
            .id(section.id)
    }

    @ViewBuilder
    private func sectionHeaderWithClear(_ section: QueueSection, subtitle: String? = nil, scrollProxy: ScrollViewProxy, clear: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            sectionLabel(section, subtitle: subtitle, scrollProxy: scrollProxy)

            Spacer(minLength: 12)

            Button("playback.queue.clear") {
                clear()
            }
        }
        .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
        .id(section.id)
    }

    private var upNextQueueSubtitle: String? {
        switch satellite.upNextStrategy {
            case .listenNow:
                String(localized: "playback.nextUpQueue.listenNow")
            case .podcast, .series, .collection:
                if let upNextOrigin = satellite.upNextOrigin {
                    "\(upNextOrigin.id.type.label): \(upNextOrigin.name)"
                } else {
                    String(localized: "loading")
                }
            default:
                nil
        }
    }

    var body: some View {
        if satellite.chapters.isEmpty && satellite.queue.isEmpty && satellite.upNextQueue.isEmpty && satellite.nowPlayingItem?.id.type != .episode {
            ContentUnavailableView("playback.queue.empty", systemImage: "list.number", description: Text("playback.queue.empty.description"))
        } else {
            ScrollViewReader { scrollProxy in
                List {
                    if !satellite.bookmarks.isEmpty {
                        Section {
                            ForEach(satellite.bookmarks) {
                                let time = Double($0.time)

                                TimeRow(title: $0.note, time: time, isActive: false, isFinished: false) {
                                    satellite.seek(to: time, insideChapter: false) {}
                                }
                                .id($0)
                                .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
                                .modifier(EditBookmarkSwipeAction(bookmark: $0))
                            }
                            .onDelete {
                                guard let currentItemID = satellite.nowPlayingItemID else {
                                    return
                                }

                                for index in $0 {
                                    satellite.deleteBookmark(at: satellite.bookmarks[index].time, from: currentItemID)
                                }
                            }
                        } header: {
                            sectionHeader(.bookmarks, scrollProxy: scrollProxy)
                        }
                    }

                    if let episode = satellite.nowPlayingItem as? Episode {
                        Section {
                            EpisodeDescription(episode: episode, textColor: isMeshActive ? .white : .label)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 12, leading: 28, bottom: 12, trailing: 28))
                                .id("playback_episode_description")
                                .accessibilityFocused($isEpisodeDescriptionFocused)
                        } header: {
                            sectionHeader(.description, scrollProxy: scrollProxy)
                        }
                    } else if !satellite.chapters.isEmpty {
                        Section {
                            ForEach(satellite.chapters) {
                                QueueChapterRow(chapter: $0)
                            }
                        } header: {
                            sectionHeader(.chapters, scrollProxy: scrollProxy)
                        }
                    }

                    if !satellite.queue.isEmpty {
                        Section {
                            ForEach(Array(satellite.queue.enumerated()), id: \.element) { (index, itemID) in
                                QueueItemRow(itemID: itemID, queueIndex: index, isUpNextQueue: false)
                            }
                            .onMove {
                                satellite.move(queueIndex: $0, to: $1)
                            }
                            .onDelete {
                                for index in $0 {
                                    satellite.remove(queueIndex: index)
                                }
                            }
                        } header: {
                            sectionHeaderWithClear(.queue, scrollProxy: scrollProxy) {
                                satellite.clearQueue()
                            }
                        }
                    }

                    if !satellite.upNextQueue.isEmpty {
                        Section {
                            ForEach(Array(satellite.upNextQueue.enumerated()), id: \.element) { (index, itemID) in
                                QueueItemRow(itemID: itemID, queueIndex: index, isUpNextQueue: true)
                            }
                            .onDelete {
                                for index in $0 {
                                    satellite.remove(upNextQueueIndex: index)
                                }
                            }
                        } header: {
                            sectionHeaderWithClear(.upNextQueue, subtitle: upNextQueueSubtitle, scrollProxy: scrollProxy) {
                                satellite.clearUpNextQueue()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .headerProminence(.increased)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
                .padding(.horizontal, -28)
                .onAppear {
                    scrollProxy.scrollTo("playback_episode_description")
                    isEpisodeDescriptionFocused = true

                    guard let chapter = satellite.chapter else {
                        return
                    }

                    scrollProxy.scrollTo(chapter, anchor: .center)
                }
            }
        }
    }
}

private struct QueueChapterRow: View {
    @Environment(Satellite.self) private var satellite

    let chapter: Chapter

    private var isFinished: Bool {
        satellite.currentTime > chapter.endOffset
    }
    private var isActive: Bool {
        satellite.currentTime >= chapter.startOffset
    }

    @ViewBuilder
    private var sleepTimerButton: some View {
        Button("sleepTimer.chapter.set", systemImage: "moon.dust.fill") {
            satellite.setSleepTimerToChapter(chapter)
        }
    }

    var body: some View {
        TimeRow(title: chapter.title, time: chapter.startOffset, isActive: isActive, isFinished: isFinished) {
            satellite.seek(to: chapter.startOffset, insideChapter: false) {}
        }
        .id(chapter)
        .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
        .contextMenu {
            sleepTimerButton
        } preview: {
            VStack(alignment: .leading, spacing: 2) {
                let remaining = (chapter.endOffset - satellite.currentTime) * satellite.playbackRate

                if remaining > 0 {
                    Text("chapter.finishedAt \(Date.now.advanced(by: remaining).formatted(date: .omitted, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(chapter.title)
                    .font(.headline)

                Text(chapter.timeOffsetFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            sleepTimerButton
                .labelStyle(.iconOnly)
                .tint(.accentColor)
        }
    }
}

private struct QueueItemRow: View {
    @Environment(Satellite.self) private var satellite

    private var tintColor: TintColor { AppSettings.shared.tintColor }

    let itemID: ItemIdentifier

    let queueIndex: Int
    let isUpNextQueue: Bool

    @State private var item: PlayableItem?
    @State private var download: DownloadStatusTracker

    init(itemID: ItemIdentifier, queueIndex: Int, isUpNextQueue: Bool) {
        self.itemID = itemID
        self.queueIndex = queueIndex
        self.isUpNextQueue = isUpNextQueue

        _download = .init(initialValue: .init(itemID: itemID))
    }

    @ViewBuilder
    private var playButton: some View {
        Button("item.play", systemImage: "play") {
            if isUpNextQueue {
                satellite.skip(upNextQueueIndex: queueIndex)
            } else {
                satellite.skip(queueIndex: queueIndex)
            }
        }
    }
    @ViewBuilder
    private var queueButton: some View {
        if isUpNextQueue {
            Button("playback.queue.add", systemImage: "list.triangle") {
                satellite.queue(itemID)
                satellite.remove(upNextQueueIndex: queueIndex)
            }
        }
    }
    @ViewBuilder
    private var removeFromQueueButton: some View {
        Button("playback.queue.remove", systemImage: "minus.circle.fill", role: .destructive) {
            if isUpNextQueue {
                satellite.remove(upNextQueueIndex: queueIndex)
            } else {
                satellite.remove(queueIndex: queueIndex)
            }
        }
    }

    var body: some View {
        Button {
            if isUpNextQueue {
                satellite.skip(upNextQueueIndex: queueIndex)
            } else {
                satellite.skip(queueIndex: queueIndex)
            }
        } label: {
            HStack(spacing: 8) {
                ItemImage(itemID: itemID, size: .small, cornerRadius: 8)
                    .frame(width: 48)

                if let item {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                        Text(item.authors, format: .list(type: .and, width: .short))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                } else {
                    ProgressView()
                }

                Spacer(minLength: 4)

                Rectangle()
                    .frame(width: 20, height: 20)
                    .hidden()
                    .overlay {
                        DownloadButton(itemID: itemID, progressVisibility: .row)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.plain)
                    }
            }
            .contentShape(.rect)
        }
        .id(itemID)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            playButton
                .labelStyle(.iconOnly)
                .tint(tintColor.color)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            queueButton
                .labelStyle(.iconOnly)
                .tint(tintColor.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            removeFromQueueButton
                .labelStyle(.iconOnly)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            ProgressButton(itemID: itemID, tint: true)
                .labelStyle(.iconOnly)
        }
        .contextMenu {
            playButton

            if isUpNextQueue {
                Button("playback.queue.add", systemImage: "text.line.last.and.arrowtriangle.forward") {
                    satellite.queue(itemID)
                    satellite.remove(upNextQueueIndex: queueIndex)
                }
            }

            Divider()

            DownloadButton(itemID: itemID, initialStatus: download.status)
            ItemCollectionMembershipEditButton(itemID: itemID)

            Divider()

            if let audiobook = item as? Audiobook {
                ItemLoadLink(itemID: audiobook.id)
            } else if let episode = item as? Episode {
                ItemLoadLink(itemID: episode.id)
                ItemLoadLink(itemID: episode.podcastID)
            }

            Divider()

            ProgressButton(itemID: itemID)

            removeFromQueueButton
        } preview: {
            if let item {
                PlayableItemContextMenuPreview(item: item)
            } else {
                ProgressView()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 28, bottom: 8, trailing: 28))
        .onAppear {
            load()
        }
    }

    private func load() {
        Task {
            guard let item = try? await itemID.resolved as? PlayableItem else {
                return
            }

            withAnimation {
                self.item = item
            }
        }
    }
}

#if DEBUG
#Preview {
    PlaybackQueue()
        .background(.background.secondary)
        .previewEnvironment()
}

#Preview {
    List {
        QueueItemRow(itemID: .fixture, queueIndex: -1, isUpNextQueue: false)
        QueueItemRow(itemID: .fixture, queueIndex: -1, isUpNextQueue: true)
    }
    .listStyle(.plain)
    .previewEnvironment()
}
#endif
