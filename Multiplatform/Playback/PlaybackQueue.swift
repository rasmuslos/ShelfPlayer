//
//  PlaybackQueue.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import TipKit
import ShelfPlayback

struct PlaybackQueue: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
    @ViewBuilder
    static func header(label: LocalizedStringKey, subtitle: String? = nil, clear: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(label)
                
                if let subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 12)
            
            Button("playback.queue.clear") {
                clear()
            }
        }
        .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
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
        if satellite.chapters.isEmpty && satellite.queue.isEmpty && satellite.upNextQueue.isEmpty {
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
                            Text("item.bookmarks")
                                .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
                        }
                    }
                    
                    if !satellite.chapters.isEmpty {
                        Section {
                            ForEach(satellite.chapters) {
                                QueueChapterRow(chapter: $0)
                            }
                        } header: {
                            Text("item.chapters")
                                .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
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
                            Self.header(label: "playback.queue") {
                                satellite.clearQueue()
                            }
                        }
                    }
                    
                    if !satellite.upNextQueue.isEmpty {
                        Section {
                            TipView(NextUpQueueTip())
                                .listRowSeparator(.hidden)
                            
                            ForEach(Array(satellite.upNextQueue.enumerated()), id: \.element) { (index, itemID) in
                                QueueItemRow(itemID: itemID, queueIndex: index, isUpNextQueue: true)
                            }
                            .onDelete {
                                for index in $0 {
                                    satellite.remove(upNextQueueIndex: index)
                                }
                            }
                        } header: {
                            Self.header(label: "playback.nextUpQueue", subtitle: upNextQueueSubtitle) {
                                satellite.clearUpNextQueue()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .headerProminence(.increased)
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.black)
                        
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .bottom, endPoint: .top)
                            .frame(height: 8)
                    }
                )
                .padding(.horizontal, -28)
                .onAppear {
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
                .tint(.accentColor)
        }
    }
}

private struct QueueItemRow: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
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
            Button("playback.queue.add", systemImage: "text.line.last.and.arrowtriangle.forward") {
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
                .tint(tintColor.color)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            queueButton
                .tint(tintColor.accent)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            removeFromQueueButton
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            ProgressButton(itemID: itemID, tint: true)
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
    
    private nonisolated func load() {
        Task {
            guard let item = try? await itemID.resolved as? PlayableItem else {
                return
            }
            
            await MainActor.withAnimation {
                self.item = item
            }
        }
    }
}

private struct NextUpQueueTip: Tip {
    let title = Text("playback.upNextQueue.tip")
    let message: Text? = Text("playback.upNextQueue.tip.description")
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

#Preview {
    List {
        Section {
            TipView(NextUpQueueTip())
        } header: {
            PlaybackQueue.header(label: "carPlay.noConnections", subtitle: "carPlay.noConnections.subtitle") {}
        }
    }
    .listStyle(.plain)
}
#endif
