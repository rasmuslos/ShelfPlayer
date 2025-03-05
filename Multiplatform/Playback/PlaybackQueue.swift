//
//  PlaybackQueue.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.03.25.
//

import SwiftUI
import ShelfPlayerKit

struct PlaybackQueue: View {
    @Environment(Satellite.self) private var satellite
    
    @ViewBuilder
    private func header(label: LocalizedStringKey, clear: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(label)
            
            Spacer(minLength: 12)
            
            Button("playback.queue.clear") {
                clear()
            }
        }
    }
    
    var body: some View {
        if satellite.chapters.isEmpty && satellite.queue.isEmpty && satellite.upNextQueue.isEmpty {
            ContentUnavailableView("queue.empty", systemImage: "list.number", description: Text("queue.empty.description"))
        } else {
            List {
                if !satellite.chapters.isEmpty {
                    Section("chapters") {
                        ForEach(satellite.chapters) {
                            QueueChapterRow(chapter: $0)
                        }
                    }
                }
                
                if !satellite.queue.isEmpty {
                    Section {
                        ForEach(satellite.queue) {
                            QueueItemRow(itemID: $0)
                        }
                    } header: {
                        header(label: "playback.queue") {
                            
                        }
                    }
                }
                
                if !satellite.upNextQueue.isEmpty {
                    Section {
                        ForEach(satellite.queue) {
                            QueueItemRow(itemID: $0)
                        }
                    } header: {
                        header(label: "playback.nextUpQueue") {
                            
                        }
                    }
                }
            }
            .listStyle(.plain)
            .headerProminence(.increased)
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
        satellite.currentTime >= chapter.startOffset && !isFinished
    }
    
    var body: some View {
        Button {
            satellite.seek(to: chapter.startOffset, insideChapter: false) {}
        } label: {
            HStack(spacing: 0) {
                Text(chapter.startOffset, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.accentColor)
                    .padding(.trailing, 12)
                
                Text(chapter.title)
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

#Preview {
    PlaybackQueue()
        .previewEnvironment()
}
