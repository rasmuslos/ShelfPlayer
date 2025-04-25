//
//  PlaybackQueue.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PlaybackQueue: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
    @ViewBuilder
    private func header(label: LocalizedStringKey, clear: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(label)
            
            Spacer(minLength: 12)
            
            Button("playback.queue.clear") {
                clear()
            }
        }
        .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
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
                                QueueTimeRow(title: $0.note, time: Double($0.time), isActive: false, isFinished: false)
                                    .id($0)
                            }
                            .onDelete {
                                guard let currentItemID = satellite.currentItemID else {
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
                            .onDelete {
                                for index in $0 {
                                    satellite.remove(queueIndex: index)
                                }
                            }
                        } header: {
                            header(label: "playback.queue") {
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
                            header(label: "playback.nextUpQueue") {
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

private struct QueueTimeRow: View {
    @Environment(Satellite.self) private var satellite
    
    let title: String
    let time: TimeInterval
    
    let isActive: Bool
    let isFinished: Bool
    
    var body: some View {
        Button {
            satellite.seek(to: time, insideChapter: false) {}
        } label: {
            HStack(spacing: 0) {
                ZStack {
                    Text(verbatim: "00:00:00")
                        .hidden()
                    
                    Text(time, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                }
                .font(.footnote)
                .fontDesign(.rounded)
                .foregroundStyle(Color.accentColor)
                .padding(.trailing, 12)
                
                Text(title)
                    .bold(isActive)
                    .foregroundStyle(isFinished ? .secondary : .primary)
                
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
    }
}
private struct QueueChapterRow: View {
    @Environment(Satellite.self) private var satellite
    
    let chapter: Chapter
    
    private var isFinished: Bool {
        satellite.currentTime > chapter.endOffset
    }
    private var isActive: Bool {
        satellite.currentTime >= chapter.startOffset && !isFinished
    }
    
    var body: some View {
        QueueTimeRow(title: chapter.title, time: chapter.startOffset, isActive: isActive, isFinished: isFinished)
            .id(chapter)
    }
}

private struct QueueItemRow: View {
    @Environment(Satellite.self) private var satellite
    
    @Default(.tintColor) private var tintColor
    
    let itemID: ItemIdentifier
    
    let queueIndex: Int
    let isUpNextQueue: Bool
    
    @State private var item: PlayableItem?
    
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
        Button("playback.queue.remove", systemImage: "minus.circle.fill") {
            if isUpNextQueue {
                satellite.remove(upNextQueueIndex: queueIndex)
            } else {
                satellite.remove(queueIndex: queueIndex)
            }
        }
        .tint(.red)
        .foregroundStyle(.red)
    }
    
    var body: some View {
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
        }
        .id(itemID)
        .contentShape(.rect)
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
            DownloadButton(itemID: itemID, tint: true)
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
            
            DownloadButton(itemID: itemID)
            
            Divider()
            
            if let audiobook = item as? Audiobook {
                NavigationLink(destination: AudiobookView(audiobook)) {
                    Label(ItemIdentifier.ItemType.audiobook.viewLabel, systemImage: "book")
                }
                
                ItemMenu(authors: audiobook.authors)
                ItemMenu(series: audiobook.series)
            } else if let episode = item as? Episode {
                ItemLoadLink(itemID: episode.id)
                ItemLoadLink(itemID: episode.podcastID)
            }
            
            Divider()
            
            ProgressButton(itemID: itemID)
            
            Divider()
            
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
