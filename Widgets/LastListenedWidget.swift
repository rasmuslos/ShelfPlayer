//
//  LastListenedWidget.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import WidgetKit
import SwiftUI
import Nuke
import Defaults
import ShelfPlayerKit

struct LastListenedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.rfk.shelfPlayer.lastListened", provider: LastListenedWidgetProvider()) {
            LastListenedWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.lastListened.title"))
        .description(Text("widget.lastListened.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LastListenedWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastListenedWidgetTimelineEntry {
        LastListenedWidgetTimelineEntry(item: nil, isDownloaded: false, isPlaying: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping @Sendable (LastListenedWidgetTimelineEntry) -> Void) {
        Task {
            completion(await getCurrent())
        }
    }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<LastListenedWidgetTimelineEntry>) -> Void) {
        Task {
            completion(Timeline(entries: [await getCurrent()], policy: .never))
        }
    }
    
    private func getCurrent() async -> LastListenedWidgetTimelineEntry {
        guard let payload = Defaults[.lastListened] else {
            return await LastListenedWidgetTimelineEntry(item: nil, isDownloaded: false, isPlaying: nil)
        }
        
        try? await PersistenceManager.shared.authorization.fetchConnections()
        
        return await LastListenedWidgetTimelineEntry(item: payload.item, isDownloaded: payload.isDownloaded, isPlaying: payload.isPlaying)
    }
}

struct LastListenedWidgetTimelineEntry: TimelineEntry, Sendable {
    var date: Date = .now
    
    var item: PlayableItem?
    var imageData: Data?
    
    var isDownloaded: Bool
    var isPlaying: Bool? = nil
    
    init(date: Date = .now, item: PlayableItem?, isDownloaded: Bool, isPlaying: Bool?) {
        self.date = date
        
        self.item = item
        imageData = nil
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
    }
    init(date: Date = .now, item: PlayableItem?, isDownloaded: Bool, isPlaying: Bool?) async {
        self.date = date
        
        self.item = item
        imageData = await item?.id.data(size: .regular)
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
    }
}

private struct LastListenedWidgetContent: View {
    let entry: LastListenedWidgetTimelineEntry
    
    private var name: String {
        guard let item = entry.item else {
            return "--"
        }
        
        return item.name
    }
    @ViewBuilder
    private var image: some View {
        Group {
            if let imageData = entry.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ItemImage(item: nil, size: .regular)
            }
        }
        .frame(width: 52)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                image
                
                Spacer(minLength: 0)
                
                if entry.item != nil {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 0)
            
            Text(name)
                .font(.headline)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 0) {
                Group {
                    if let isPlaying = entry.isPlaying {
                        if isPlaying {
                            Button("pause", systemImage: "pause.fill", intent: PauseIntent())
                        } else {
                            Button("play", systemImage: "play.fill", intent: PlayIntent())
                        }
                    } else if let item = entry.item {
                        Text(verbatim: ":(")
                    } else {
                        Button("play", systemImage: "play.fill") {}
                            .disabled(true)
                    }
                }
                .font(.footnote)
                .controlSize(.small)
                .foregroundStyle(.accent)
                
                Spacer(minLength: 12)
                
                if entry.isDownloaded {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Rectangle()
                .fill(.background)
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    LastListenedWidget()
} timeline: {
    LastListenedWidgetTimelineEntry(item: nil, isDownloaded: true, isPlaying: nil)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: false, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: true, isPlaying: false)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: true, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: false, isPlaying: false)
}
#Preview(as: .systemMedium) {
    LastListenedWidget()
} timeline: {
    LastListenedWidgetTimelineEntry(item: nil, isDownloaded: true, isPlaying: nil)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: true, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: false, isPlaying: false)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: false, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: true, isPlaying: false)
}
#endif
