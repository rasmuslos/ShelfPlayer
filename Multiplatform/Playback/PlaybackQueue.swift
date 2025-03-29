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
            ContentUnavailableView("queue.empty", systemImage: "list.number", description: Text("queue.empty.description"))
        } else {
            ScrollViewReader { scrollProxy in
                List {
                    if !satellite.bookmarks.isEmpty {
                        Section {
                            ForEach(satellite.bookmarks) {
                                QueueTimeRow(title: $0.note, time: Double($0.time), isActive: false, isFinished: false)
                                    .id($0)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
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
                            Text("bookmarks")
                                .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
                        }
                    }
                    
                    if !satellite.chapters.isEmpty {
                        Section {
                            ForEach(satellite.chapters) {
                                QueueChapterRow(chapter: $0)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
                            }
                        } header: {
                            Text("chapters")
                                .listRowInsets(.init(top: 12, leading: 28, bottom: 12, trailing: 28))
                        }
                    }
                    
                    if !satellite.queue.isEmpty {
                        Section {
                            ForEach(Array(satellite.queue.enumerated()), id: \.element) { (index, itemID) in
                                QueueItemRow(itemID: itemID)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(.init(top: 8, leading: 28, bottom: 8, trailing: 28))
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button("play", systemImage: "play") {
                                            satellite.skip(queueIndex: index)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button("queue.remove", systemImage: "minus.circle.fill") {
                                            satellite.remove(queueIndex: index)
                                        }
                                        .tint(.red)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        ProgressButton(itemID: itemID)
                                    }
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
                                QueueItemRow(itemID: itemID)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(.init(top: 8, leading: 28, bottom: 8, trailing: 28))
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button("play", systemImage: "play") {
                                            satellite.skip(upNextQueueIndex: index)
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button("queue.add", systemImage: "text.line.last.and.arrowtriangle.forward") {
                                            satellite.queue(itemID)
                                            satellite.remove(upNextQueueIndex: index)
                                        }
                                        .tint(tintColor.accent)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button("queue.remove", systemImage: "minus.circle.fill") {
                                            satellite.remove(upNextQueueIndex: index)
                                        }
                                        .tint(.red)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        ProgressButton(itemID: itemID)
                                    }
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
    let itemID: ItemIdentifier
    
    @State private var item: Item?
    
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
                ProgressIndicator()
            }
        }
        .id(itemID)
        .onAppear {
            load()
        }
    }
    
    private nonisolated func load() {
        Task {
            guard let item = try? await itemID.resolved else {
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
        .previewEnvironment()
        .background(.background.secondary)
}
#endif
